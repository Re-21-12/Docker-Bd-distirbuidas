#!/bin/bash

echo "🚀 Levantando master..."
docker compose up -d master
sleep 10

echo "🚀 Levantando slaves..."
docker compose up -d slave1 slave2 slave3 slave4 slave5
sleep 10

./generate_dump.sh
./setup_replication.sh
