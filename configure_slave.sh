#!/bin/bash

# Configuración
MASTER_CONTAINER="mariadb_master"
REPL_USER="repl"
REPL_PASS="replpass"
ROOT_PASS="rootpass"
SLAVES=("mariadb_slave1" "mariadb_slave2" "mariadb_slave3" "mariadb_slave4" "mariadb_slave5")
WAIT_TIMEOUT=30  # Segundos para esperar que los contenedores estén listos

# Función para verificar comandos
check_command() {
  if [ $? -ne 0 ]; then
    echo "❌ Error en: $1"
    exit 1
  fi
}

# Función para esperar que un contenedor esté listo
wait_for_container() {
  local container=$1
  local counter=0
  
  echo -n "Esperando a que $container esté listo..."
  until docker inspect -f '{{.State.Running}}' $container 2>/dev/null | grep -q "true"; do
    counter=$((counter + 1))
    if [ $counter -ge $WAIT_TIMEOUT ]; then
      echo "❌ Tiempo de espera agotado"
      return 1
    fi
    sleep 1
    echo -n "."
  done
  echo "✅"
  return 0
}

# 1. Verificar que todos los contenedores estén en ejecución
echo "🔍 Verificando estado de los contenedores..."

# Verificar master
if ! wait_for_container $MASTER_CONTAINER; then
  echo "   Ejecuta primero: docker compose up -d"
  exit 1
fi

# Verificar slaves
for SLAVE in "${SLAVES[@]}"; do
  if ! wait_for_container $SLAVE; then
    echo "   Algunos slaves no están disponibles. Continuando con los disponibles..."
  fi
done

# 2. Configurar usuario de replicación en el master
echo "🔧 Configurando usuario de replicación en el master..."
docker exec -i $MASTER_CONTAINER mysql -uroot -p$ROOT_PASS <<EOF
CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
FLUSH PRIVILEGES;
EOF
check_command "Creación de usuario de replicación"

# 3. Obtener posición del binlog (con verificación extendida)
echo "📌 Obteniendo posición del binlog..."
for i in {1..3}; do  # Reintentos
  MASTER_STATUS=$(docker exec -i $MASTER_CONTAINER mysql -uroot -p$ROOT_PASS -N -e "SHOW MASTER STATUS;" 2>/dev/null)
  
  if [ -n "$MASTER_STATUS" ]; then
    read MASTER_LOG_FILE MASTER_LOG_POS <<< $(echo "$MASTER_STATUS" | awk '{print $1, $2}')
    if [ -n "$MASTER_LOG_FILE" ] && [ -n "$MASTER_LOG_POS" ]; then
      break
    fi
  fi
  
  if [ $i -eq 3 ]; then
    echo "❌ No se pudo obtener MASTER STATUS después de 3 intentos. Verifica:"
    echo "   - Que el master esté completamente inicializado"
    echo "   - Que el usuario root tenga los permisos correctos"
    echo "   - Que el binlog esté habilitado en /etc/mysql/my.cnf:"
    echo "     [mysqld]"
    echo "     log-bin=mysql-bin"
    echo "     server-id=1"
    exit 1
  fi
  
  sleep 5
done

echo "   Archivo Binlog: $MASTER_LOG_FILE"
echo "   Posición: $MASTER_LOG_POS"
echo

# 4. Configurar cada slave con verificación extendida
for SLAVE in "${SLAVES[@]}"; do
  echo "⚙️ Configurando slave: $SLAVE"
  
  # Verificar que el contenedor esté activo
  if ! docker inspect -f '{{.State.Running}}' $SLAVE 2>/dev/null | grep -q "true"; then
    echo "   ⚠️ Contenedor no está en ejecución, omitiendo..."
    continue
  fi

  # Verificar que MySQL esté respondiendo
  if ! docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS -e "SELECT 1" &>/dev/null; then
    echo "   ⚠️ MySQL no responde en el slave, omitiendo..."
    continue
  fi

  # Configurar replicación con reintentos
  for attempt in {1..2}; do
    docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS <<EOF
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_CONTAINER',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_LOG_FILE='$MASTER_LOG_FILE',
  MASTER_LOG_POS=$MASTER_LOG_POS,
  MASTER_CONNECT_RETRY=10;
START SLAVE;
EOF
    
    if [ $? -eq 0 ]; then
      break
    elif [ $attempt -eq 2 ]; then
      echo "   ❌ Fallo al configurar replicación después de 2 intentos"
      continue 2
    fi
    sleep 5
  done

  # Verificación detallada del estado
  SLAVE_STATUS=$(docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS -e "SHOW SLAVE STATUS\G")
  
  # Extraer valores clave
  IO_RUNNING=$(echo "$SLAVE_STATUS" | awk '/Slave_IO_Running:/ {print $2}')
  SQL_RUNNING=$(echo "$SLAVE_STATUS" | awk '/Slave_SQL_Running:/ {print $2}')
  LAST_IO_ERROR=$(echo "$SLAVE_STATUS" | awk '/Last_IO_Error:/ {print $2}')
  LAST_SQL_ERROR=$(echo "$SLAVE_STATUS" | awk '/Last_SQL_Error:/ {print $2}')

  if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
    echo "   ✅ Replicación activa"
    echo "   🔄 Retardo: $(echo "$SLAVE_STATUS" | awk '/Seconds_Behind_Master:/ {print $2}') segundos"
  else
    echo "   ❌ Problema en replicación:"
    [ -n "$LAST_IO_ERROR" ] && echo "   - IO Error: $LAST_IO_ERROR"
    [ -n "$LAST_SQL_ERROR" ] && echo "   - SQL Error: $LAST_SQL_ERROR"
    
    # Intentar reparación automática para errores comunes
    if [[ "$LAST_SQL_ERROR" == *"Duplicate entry"* ]]; then
      echo "   🔄 Intentando reparar error de duplicados..."
      docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS -e "STOP SLAVE; SET GLOBAL sql_slave_skip_counter = 1; START SLAVE;"
    fi
  fi
  echo "-------------------------------------------"
done

# 5. Verificación final consolidada
echo "🎉 Resumen final:"
printf "%-15s %-10s %-10s %s\n" "SLAVE" "IO" "SQL" "ESTADO"
for SLAVE in "${SLAVES[@]}"; do
  if docker inspect -f '{{.State.Running}}' $SLAVE 2>/dev/null | grep -q "true"; then
    STATUS=$(docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS -e "SHOW SLAVE STATUS\G" 2>/dev/null | \
      awk '/Slave_(IO|SQL)_Running:/ {gsub("Yes","✅"); gsub("No","❌"); print $2}' | tr '\n' ' ')
    printf "%-15s %-10s %-10s\n" "$SLAVE" $STATUS
  else
    printf "%-15s %-10s %-10s %s\n" "$SLAVE" "" "" "🔴 Contenedor no activo"
  fi
done

echo -e "\nPara ver detalles:"
echo "   docker exec -it mariadb_slave1 mysql -uroot -p$ROOT_PASS -e \"SHOW SLAVE STATUS\\G\""