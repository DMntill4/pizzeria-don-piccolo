-- =====================================================================
-- PIZZERÍA DON PICCOLO - Vistas de reportes
-- Ejecutar después de database.sql
-- =====================================================================
USE pizzeria_don_piccolo;

-- ---------------------------------------------------------------------
-- VISTA 1: vista_resumen_pedidos_cliente
-- Nombre del cliente, cantidad de pedidos y total gastado.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vista_resumen_pedidos_cliente;

CREATE VIEW vista_resumen_pedidos_cliente AS
SELECT
    c.id_cliente,
    c.nombre                       AS cliente,
    COUNT(p.id_pedido)             AS cantidad_pedidos,
    IFNULL(SUM(p.total), 0)        AS total_gastado
FROM clientes c
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre;

-- ---------------------------------------------------------------------
-- VISTA 2: vista_desempeno_repartidores
-- Número de entregas, tiempo promedio de entrega (minutos) y zona.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vista_desempeno_repartidores;

CREATE VIEW vista_desempeno_repartidores AS
SELECT
    r.id_repartidor,
    r.nombre                                                        AS repartidor,
    r.zona_asignada                                                 AS zona,
    COUNT(d.id_domicilio)                                           AS numero_entregas,
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega))        AS tiempo_promedio_minutos
FROM repartidores r
LEFT JOIN domicilios d
       ON d.id_repartidor = r.id_repartidor
      AND d.hora_entrega IS NOT NULL
GROUP BY r.id_repartidor, r.nombre, r.zona_asignada;

-- ---------------------------------------------------------------------
-- VISTA 3: vista_stock_bajo
-- Ingredientes cuyo stock actual está por debajo del mínimo permitido.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vista_stock_bajo;

CREATE VIEW vista_stock_bajo AS
SELECT
    id_ingrediente,
    nombre,
    unidad_medida,
    stock_actual,
    stock_minimo,
    (stock_minimo - stock_actual) AS faltante
FROM ingredientes
WHERE stock_actual < stock_minimo;