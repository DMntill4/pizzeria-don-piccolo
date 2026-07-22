
-- Usamos database ya creada anteriormente --
USE pizzeria_don_piccolo;

-- ELIMINAMOS tablas para no tener interferencias--
DROP TABLE IF EXISTS repartidores;
DROP TABLE IF EXISTS domicilios;


-- creacion de las dos tablas con las nuevas indicaciones en repartidor y domicilios --
CREATE TABLE repartidores (
    id_repartidor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    zona_asignada VARCHAR(100) NOT NULL,
    estado ENUM('activo', 'inactivo') NOT NULL DEFAULT 'activo'
) ENGINE=InnoDB;

CREATE TABLE domicilios (
    id_domicilio INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_repartidor INT,
    hora_salida DATETIME NOT NULL,
    hora_entrega DATETIME DEFAULT NULL,
    estado ENUM('en_ruta', 'entregado', 'cancelado') NOT NULL DEFAULT 'en_ruta',
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor) ON DELETE SET NULL
) ENGINE=InnoDB;


-- valores de prueba para las views Y las consultas --
INSERT INTO repartidores (nombre, telefono, zona_asignada, estado) VALUES
('Guerra', '123456789', 'Norte', 'activo'),
('Diego', '300123456', 'Sur', 'activo'),
('Camilo', '30098765432', 'Oriente', 'activo'),
('Filipinas', '3002345678', 'Occidente', 'inactivo');

INSERT INTO pedidos (id_cliente, metodo_pago, estado, total) VALUES
(1, 'Efectivo', 'Entregado', 45000.00),
(1, 'Tarjeta', 'Entregado', 32000.00),
(1, 'App', 'Entregado', 55000.00),
(1, 'Efectivo', 'Cancelado', 0.00);

-- insertamos valores de prueba en domicilios para luego llamar en consultas --
INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida, hora_entrega, estado) VALUES
(2, 1, '2026-07-22 12:00:00', '2026-07-22 12:25:00', 'entregado');

INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida,  hora_entrega, estado) VALUES
(3, 1, '2026-07-22 12:00:00', '2026-07-22 12:55:00', 'entregado');

INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida,  hora_entrega, estado) VALUES
(4, 2, '2026-07-22 12:30:00', '2026-07-22 12:35:00', 'entregado');

INSERT INTO domicilios (id_pedido, id_repartidor, hora_salida,  hora_entrega, estado) VALUES
(5, 2, '2026-07-22 4:30:00', NULL, 'cancelado');


-- 1. Consulta: Total de entregas por cada repartidor con el total acumulado en pedidos entregados --
SELECT 
    r.nombre AS nombre_repartidor,
    COUNT(d.id_domicilio) AS entregas_realizadas,
    SUM(p.total) AS total_acumulado
FROM repartidores r
INNER JOIN domicilios d ON r.id_repartidor = d.id_repartidor
INNER JOIN pedidos p ON d.id_pedido = p.id_pedido
WHERE d.estado = 'entregado'
GROUP BY r.id_repartidor, r.nombre;

-- 2. Consulta: Pedidos cuyo tiempo de hora de salida y hora de entrega fueron mas de 40 minutos --
SELECT 
    p.id_pedido,
    d.hora_salida,
    d.hora_entrega,
    TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega) AS minutos_transcurridos
FROM pedidos p
INNER JOIN domicilios d ON p.id_pedido = d.id_pedido
WHERE TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega) > 40;

-- 3. Consulta: Repartidores activos sin domiciolios asignados --
SELECT 
    r.id_repartidor,
    r.nombre AS nombre_repartidor,
    r.telefono,
    r.zona_asignada,
    r.estado
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
WHERE r.estado = 'activo'
  AND d.id_domicilio IS NULL;


-- Vista del resumen de desempeno
CREATE VIEW vista_desempeno_repartidor AS
SELECT 
	r.nombre as nombre_repartidor,
    COUNT(CASE WHEN d.estado = 'entregado' THEN 1 END) AS entregas_totales,
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS promedio_minutos_entrega
FROM repartidores r
LEFT JOIN domicilios d ON r.id_repartidor = d.id_repartidor
GROUP BY r.id_repartidor, r.nombre;

SELECT * FROM vista_desempeno_repartidor