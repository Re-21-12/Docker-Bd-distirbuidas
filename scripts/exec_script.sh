docker exec -i mariadb_master mysql -uroot -prootpass < init.sql
# 
docker exec -i mariadb_master mysql -uroot -prootpass -e "CREATE DATABASE IF NOT EXISTS vuelos;"
docker exec -i mariadb_master mysql -uroot -prootpass vuelos < init.sql


docker exec -it mariadb_slave1 mysql -uroot -prootpass -e "USE vuelos; SELECT * FROM test_rep;"