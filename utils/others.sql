CREATE USER 'readonly'@'%' IDENTIFIED BY 'readonlypass';
GRANT SELECT ON vuelos.* TO 'readonly'@'%';
FLUSH PRIVILEGES;
