#cargar script
docker exec -i mariadb_master mysql -uroot -prootpass < init.sql
# 
docker exec -i mariadb_master mysql -uroot -prootpass -e "CREATE DATABASE IF NOT EXISTS vuelos;"
docker exec -i mariadb_master mysql -uroot -prootpass vuelos < init.sql


docker exec -it mariadb_slave1 mysql -uroot -prootpass -e "USE vuelos; SELECT * FROM test_rep;"

# Ver Ip
docker inspect mariadb_master | grep "IPAddress"

# conectarme desde otro container
docker exec -it mariadb_slave1 bash
root@847c64322da8:/# mysql -h 172.18.0.2 -u root -p vuelos

# reiniciar slaves

# Para slave4
docker exec mariadb_slave4 mysql -uroot -prootpass -e "STOP SLAVE; RESET SLAVE ALL;"
docker exec mariadb_slave4 mysql -uroot -prootpass -e "CHANGE MASTER TO MASTER_HOST='mariadb_master', MASTER_USER='repl', MASTER_PASSWORD='replpass', MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=328; START SLAVE;"

# Para slave5
docker exec mariadb_slave5 mysql -uroot -prootpass -e "STOP SLAVE; RESET SLAVE ALL;"
docker exec mariadb_slave5 mysql -uroot -prootpass -e "CHANGE MASTER TO MASTER_HOST='mariadb_master', MASTER_USER='repl', MASTER_PASSWORD='replpass', MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=328; START SLAVE;"