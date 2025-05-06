CREATE DATABASE IF NOT EXISTS vuelos;
USE vuelos;
CREATE TABLE pais(
    codigo_pais VARCHAR(3) NOT NULL PRIMARY KEY,
    nombre_pais VARCHAR(255) NOT NULL
);

CREATE TABLE ciudad(
    codigo_ciudad VARCHAR(5) NOT NULL PRIMARY KEY,
    nombre_ciudad VARCHAR(255) NOT NULL,
    codigo_pais VARCHAR(3) NOT NULL,
    FOREIGN KEY (codigo_pais) REFERENCES pais(codigo_pais)
);

CREATE TABLE aeropuerto(
    id_aeropuerto INT NOT NULL PRIMARY KEY,
    codigo_pais VARCHAR(3) NOT NULL,
    codigo_ciudad VARCHAR(5) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    FOREIGN KEY (codigo_pais) REFERENCES pais(codigo_pais),
    FOREIGN KEY (codigo_ciudad) REFERENCES ciudad(codigo_ciudad)
);

CREATE TABLE aerolinea(
    id_aerolinea VARCHAR(3) NOT NULL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL
);

CREATE TABLE avion(
    id_avion INT NOT NULL PRIMARY KEY,
    matricula VARCHAR(20) NOT NULL UNIQUE,
    modelo VARCHAR(100) NOT NULL,
    capacidad_total INT NOT NULL,
    id_aerolinea VARCHAR(3) NOT NULL,
    FOREIGN KEY (id_aerolinea) REFERENCES aerolinea(id_aerolinea)
);

CREATE TABLE vuelo(
    numero_vuelo VARCHAR(10) NOT NULL PRIMARY KEY,
    hora_salida DATETIME NOT NULL,
    hora_llegada DATETIME NOT NULL,
    aeropuerto_origen INT NOT NULL,
    aeropuerto_destino INT NOT NULL,
    id_avion INT NOT NULL,
    FOREIGN KEY (aeropuerto_origen) REFERENCES aeropuerto(id_aeropuerto),
    FOREIGN KEY (aeropuerto_destino) REFERENCES aeropuerto(id_aeropuerto),
    FOREIGN KEY (id_avion) REFERENCES avion(id_avion)
);

CREATE TABLE pasajero(
    id_pasajero INT UNSIGNED NOT NULL PRIMARY KEY,
    primer_nombre VARCHAR(255) NOT NULL,
    segundo_nombre VARCHAR(255),
    tercer_nombre VARCHAR(255),
    primer_apellido VARCHAR(255) NOT NULL,
    segundo_apellido VARCHAR(255) NOT NULL,
    pasaporte VARCHAR(20) NOT NULL UNIQUE,
    codigo_pais VARCHAR(3) NOT NULL,
    codigo_ciudad VARCHAR(5) NOT NULL,
    FOREIGN KEY (codigo_pais) REFERENCES pais(codigo_pais),
    FOREIGN KEY (codigo_ciudad) REFERENCES ciudad(codigo_ciudad)
);

-- Tabla de asientos
CREATE TABLE plaza(
    letra_fila VARCHAR(4) NOT NULL,
    numero_plaza INT NOT NULL,
    PRIMARY KEY (letra_fila, numero_plaza)
);

CREATE TABLE reserva(
    id_reserva INT UNSIGNED NOT NULL PRIMARY KEY,
    letra_fila VARCHAR(4) NOT NULL,
    numero_plaza INT NOT NULL,
    fecha_reserva DATE NOT NULL,
    estado ENUM('confirmado', 'cancelado') NOT NULL DEFAULT 'confirmado',
    numero_vuelo VARCHAR(10) NOT NULL,
    FOREIGN KEY (letra_fila, numero_plaza) REFERENCES plaza(letra_fila, numero_plaza),
    FOREIGN KEY (numero_vuelo) REFERENCES vuelo(numero_vuelo)
);

CREATE TABLE reserva_pasajero(
    id_reserva INT UNSIGNED NOT NULL,
    id_pasajero INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_reserva, id_pasajero),
    FOREIGN KEY (id_reserva) REFERENCES reserva(id_reserva),
    FOREIGN KEY (id_pasajero) REFERENCES pasajero(id_pasajero)
);

CREATE TABLE telefono(
    numero_telefono VARCHAR(20) NOT NULL PRIMARY KEY,
    id_pasajero INT UNSIGNED NOT NULL,
    FOREIGN KEY (id_pasajero) REFERENCES pasajero(id_pasajero)
);

CREATE TABLE correo_electronico(
    correo VARCHAR(255) NOT NULL PRIMARY KEY,
    id_pasajero INT UNSIGNED NOT NULL,
    FOREIGN KEY (id_pasajero) REFERENCES pasajero(id_pasajero)
);



INSERT INTO pais (codigo_pais, nombre_pais) VALUES ('MEX', 'México');
SELECT * FROM pais;

INSERT INTO ciudad (codigo_ciudad, nombre_ciudad, codigo_pais) VALUES ('MEX', 'Ciudad de México', 'MEX');
SELECT * FROM ciudad;

INSERT INTO aeropuerto (id_aeropuerto, codigo_pais, codigo_ciudad, nombre) VALUES (1, 'MEX', 'MEX', 'Aeropuerto Internacional Benito Juárez');
SELECT * FROM aeropuerto;

INSERT INTO aerolinea (id_aerolinea, nombre) VALUES ('AAL', 'American Airlines');
SELECT * FROM aerolinea;

INSERT INTO avion (id_avion, matricula, modelo, capacidad_total, id_aerolinea) VALUES (101, 'XA-ABC', 'Boeing 737-800', 180, 'AAL');
SELECT * FROM avion;

INSERT INTO vuelo (numero_vuelo, hora_salida, hora_llegada, aeropuerto_origen, aeropuerto_destino, id_avion) 
VALUES ('AA100', '2023-12-25 08:00:00', '2023-12-25 11:00:00', 1, 1, 101);
SELECT * FROM vuelo;

INSERT INTO pasajero (id_pasajero, primer_nombre, primer_apellido, segundo_apellido, pasaporte, codigo_pais, codigo_ciudad) 
VALUES (5001, 'Juan', 'Pérez', 'Gómez', 'MXP123456', 'MEX', 'MEX');
SELECT * FROM pasajero;

INSERT INTO plaza (letra_fila, numero_plaza) VALUES ('A', 1);
SELECT * FROM plaza;

INSERT INTO reserva (id_reserva, letra_fila, numero_plaza, fecha_reserva, numero_vuelo) 
VALUES (1001, 'A', 1, '2023-12-20', 'AA100');
SELECT * FROM reserva;

INSERT INTO reserva_pasajero (id_reserva, id_pasajero) VALUES (1001, 5001);
SELECT * FROM reserva_pasajero;

INSERT INTO telefono (numero_telefono, id_pasajero) VALUES ('+525512345678', 5001);
SELECT * FROM telefono;

INSERT INTO correo_electronico (correo, id_pasajero) VALUES ('juan.perez@email.com', 5001);
SELECT * FROM correo_electronico;