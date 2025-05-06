#!/bin/bash

MASTER_CONTAINER="mariadb_master"
REPL_USER="repl"
REPL_PASS="replpass"
ROOT_PASS="rootpass"

# Lista de esclavos a configurar
SLAVES=("mariadb_slave1" "mariadb_slave2" "mariadb_slave3" "mariadb_slave4" "mariadb_slave5")

# Crear el usuario de replicación en el maestro
echo "Creando usuario de replicación en el maestro..."
docker exec -i $MASTER_CONTAINER mysql -uroot -p$ROOT_PASS <<EOF
CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
FLUSH PRIVILEGES;
EOF

echo "Usuario de replicación configurado."
echo

# Obtener archivo y posición del binlog desde el maestro (una sola vez)
read MASTER_LOG_FILE MASTER_LOG_POS <<< $(docker exec -i $MASTER_CONTAINER mysql -uroot -p$ROOT_PASS -N -e "SHOW MASTER STATUS;" | awk '{print $1, $2}')

echo "Usando:"
echo "  Log File: $MASTER_LOG_FILE"
echo "  Log Pos : $MASTER_LOG_POS"
echo

# Configurar todos los esclavos
for SLAVE in "${SLAVES[@]}"; do
  echo "Configurando esclavo: $SLAVE"

  docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS <<EOF
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_CONTAINER',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_LOG_FILE='$MASTER_LOG_FILE',
  MASTER_LOG_POS=$MASTER_LOG_POS;
START SLAVE;
SHOW SLAVE STATUS\G
EOF

  echo "-------------------------------------------"
done
