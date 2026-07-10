-- =====================================================================
-- PIZZERÍA DON PICCOLO - Funciones y Procedimientos
-- Ejecutar después de database.sql
-- =====================================================================
USE pizzeria_don_piccolo;

-- ---------------------------------------------------------------------
-- FUNCIÓN 1: fn_calcular_total_pedido
-- Calcula el total de un pedido: (suma de pizzas + costo de envío) + IVA
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_calcular_total_pedido;

DELIMITER $$
CREATE FUNCTION fn_calcular_total_pedido(p_id_pedido INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_subtotal DECIMAL(10,2) DEFAULT 0;
    DECLARE v_envio    DECIMAL(10,2) DEFAULT 0;
    DECLARE v_iva      DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total    DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(cantidad * precio_unitario), 0)
      INTO v_subtotal
      FROM pedido_detalle
     WHERE id_pedido = p_id_pedido;

    SELECT IFNULL(costo_envio, 0)
      INTO v_envio
      FROM domicilios
     WHERE id_pedido = p_id_pedido;

    SET v_iva   = (v_subtotal + v_envio) * 0.19;   -- IVA 19%
    SET v_total = v_subtotal + v_envio + v_iva;

    RETURN v_total;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- FUNCIÓN 2: fn_ganancia_neta_diaria
-- Calcula la ganancia neta de un día: ventas entregadas - costo de
-- los ingredientes consumidos ese día
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_ganancia_neta_diaria;

DELIMITER $$
CREATE FUNCTION fn_ganancia_neta_diaria(p_fecha DATE)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ventas DECIMAL(12,2) DEFAULT 0;
    DECLARE v_costos DECIMAL(12,2) DEFAULT 0;

    -- Total vendido en pedidos entregados ese día
    SELECT IFNULL(SUM(p.total), 0)
      INTO v_ventas
      FROM pedidos p
     WHERE DATE(p.fecha_hora) = p_fecha
       AND p.estado = 'Entregado';

    -- Costo de ingredientes consumidos en pedidos de ese día
    SELECT IFNULL(SUM(pd.cantidad * pi.cantidad_requerida * i.costo_unitario), 0)
      INTO v_costos
      FROM pedido_detalle pd
      JOIN pedidos p ON p.id_pedido = pd.id_pedido
      JOIN pizza_ingredientes pi ON pi.id_pizza = pd.id_pizza
      JOIN ingredientes i ON i.id_ingrediente = pi.id_ingrediente
     WHERE DATE(p.fecha_hora) = p_fecha
       AND p.estado = 'Entregado';

    RETURN v_ventas - v_costos;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- PROCEDIMIENTO 1: sp_marcar_pedido_entregado
-- Cambia el estado del pedido asociado a 'Entregado'.
-- Es invocado automáticamente desde el trigger trg_pedido_entregado
-- (ver triggers.sql) cuando se registra la hora_entrega del domicilio.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_marcar_pedido_entregado;

DELIMITER $$
CREATE PROCEDURE sp_marcar_pedido_entregado(IN p_id_pedido INT)
BEGIN
    UPDATE pedidos
       SET estado = 'Entregado'
     WHERE id_pedido = p_id_pedido;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- PROCEDIMIENTO 2 (utilidad): sp_registrar_entrega
-- Registra la hora de entrega de un domicilio. Al hacerlo, dispara
-- automáticamente los triggers que liberan al repartidor y marcan
-- el pedido como entregado.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_entrega;

DELIMITER $$
CREATE PROCEDURE sp_registrar_entrega(IN p_id_domicilio INT)
BEGIN
    UPDATE domicilios
       SET hora_entrega = NOW()
     WHERE id_domicilio = p_id_domicilio;
END$$
DELIMITER ;