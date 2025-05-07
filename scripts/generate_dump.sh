#!/bin/bash

MASTER="mariadb_master"
SLAVES=("mariadb_slave1" "mariadb_slave2" "mariadb_slave3" "mariadb_slave4" "mariadb_slave5")
ROOT_PASS="rootpass"

# Paso 1: Generar el dump con información de replicación
echo "Generando dump desde el master..."
mkdir -p ../dump
docker exec -i $MASTER mysqldump -uroot -p$ROOT_PASS --all-databases --master-data=2 > ../dump/dump.sql

# Paso 2: Cargar el dump en cada slave
echo "Cargando dump en los slaves..."
for SLAVE in "${SLAVES[@]}"; do
  docker cp ../dump/dump.sql "$SLAVE":/dump.sql
  docker exec -i "$SLAVE" mysql -uroot -p$ROOT_PASS < /dump.sql
  echo "✔️ Dump cargado en $SLAVE"
done

echo "✅ Dump generado y cargado correctamente."
