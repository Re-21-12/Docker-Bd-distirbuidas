# Docker-Bd-distirbuidas
```
0. Encender docker
docker compose up -d
1. Cargar configure_slave.sh 
2. Confirmar conexiones
3. Cargar script en master 
docker exec -i mariadb_master mysql -uroot -prootpass < init.sql
docker exec -i mariadb_master mysql -uroot -prootpass vuelos < init.sql
4. Hacer select 
docker exec -it mariadb_slave1 mysql -uroot -prootpass -e "USE vuelos; SELECT * FROM aeropuerto;"

```