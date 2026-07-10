-- =====================================================================
-- PIZZERÍA DON PICCOLO - Consultas SQL requeridas
-- Ejecutar después de database.sql (y vistas.sql si se desea usarlas)
-- =====================================================================
USE pizzeria_don_piccolo;

-- ---------------------------------------------------------------------
-- 1. Clientes con pedidos entre dos fechas (BETWEEN)
-- ---------------------------------------------------------------------
SELECT DISTINCT
    c.id_cliente,
    c.nombre,
    c.telefono
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.fecha_hora BETWEEN '2026-07-01 00:00:00' AND '2026-07-31 23:59:59';

-- ---------------------------------------------------------------------
-- 2. Pizzas más vendidas (GROUP BY y COUNT)
-- ---------------------------------------------------------------------
SELECT
    pz.id_pizza,
    pz.nombre,
    SUM(pd.cantidad) AS unidades_vendidas
FROM pedido_detalle pd
JOIN pizzas pz ON pz.id_pizza = pd.id_pizza
GROUP BY pz.id_pizza, pz.nombre
ORDER BY unidades_vendidas DESC;

-- ---------------------------------------------------------------------
-- 3. Pedidos entregados por repartidor (JOIN)
-- ---------------------------------------------------------------------
SELECT
    r.id_repartidor,
    r.nombre AS repartidor,
    r.zona_asignada,
    COUNT(d.id_domicilio) AS total_pedidos
FROM repartidores r
JOIN domicilios d ON d.id_repartidor = r.id_repartidor
JOIN pedidos p     ON p.id_pedido = d.id_pedido
GROUP BY r.id_repartidor, r.nombre, r.zona_asignada
ORDER BY total_pedidos DESC;

-- ---------------------------------------------------------------------
-- 4. Promedio de tiempo de entrega por zona (AVG y JOIN)
-- ---------------------------------------------------------------------
SELECT
    r.zona_asignada AS zona,
    AVG(TIMESTAMPDIFF(MINUTE, d.hora_salida, d.hora_entrega)) AS promedio_minutos
FROM domicilios d
JOIN repartidores r ON r.id_repartidor = d.id_repartidor
WHERE d.hora_entrega IS NOT NULL
  AND d.hora_salida  IS NOT NULL
GROUP BY r.zona_asignada;

-- ---------------------------------------------------------------------
-- 5. Clientes que gastaron más de un monto determinado (HAVING)
-- ---------------------------------------------------------------------
SELECT
    c.id_cliente,
    c.nombre,
    SUM(p.total) AS total_gastado
FROM clientes c
JOIN pedidos p ON p.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre
HAVING SUM(p.total) > 200000
ORDER BY total_gastado DESC;

-- ---------------------------------------------------------------------
-- 6. Búsqueda por coincidencia parcial del nombre de la pizza (LIKE)
-- ---------------------------------------------------------------------
SELECT
    id_pizza,
    nombre,
    tamano,
    precio_base,
    tipo
FROM pizzas
WHERE nombre LIKE '%pepperoni%';

-- ---------------------------------------------------------------------
-- 7. Subconsulta: clientes frecuentes (más de 5 pedidos en el mes actual)
-- ---------------------------------------------------------------------
SELECT
    c.id_cliente,
    c.nombre,
    c.telefono
FROM clientes c
WHERE c.id_cliente IN (
    SELECT p.id_cliente
    FROM pedidos p
    WHERE YEAR(p.fecha_hora)  = YEAR(CURDATE())
      AND MONTH(p.fecha_hora) = MONTH(CURDATE())
    GROUP BY p.id_cliente
    HAVING COUNT(*) > 5
);