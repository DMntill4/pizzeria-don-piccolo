-- =====================================================================
-- PIZZERÍA DON PICCOLO - Triggers
-- Ejecutar después de database.sql y funciones.sql
-- =====================================================================
USE pizzeria_don_piccolo;

-- ---------------------------------------------------------------------
-- TRIGGER 1: trg_actualizar_stock
-- Valida que haya stock suficiente y descuenta el stock de cada
-- ingrediente según la receta de la pizza. Si falta stock, rechaza
-- el insert con un error.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_actualizar_stock;

DELIMITER $$
CREATE TRIGGER trg_actualizar_stock
BEFORE INSERT ON pedido_detalle
FOR EACH ROW
BEGIN
    DECLARE v_faltante INT DEFAULT 0;

    SELECT COUNT(*) INTO v_faltante
      FROM pizza_ingredientes pi
      JOIN ingredientes i ON i.id_ingrediente = pi.id_ingrediente
     WHERE pi.id_pizza = NEW.id_pizza
       AND i.stock_actual < (pi.cantidad_requerida * NEW.cantidad);

    IF v_faltante > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Stock insuficiente para preparar esta pizza';
    END IF;

    UPDATE ingredientes i
      JOIN pizza_ingredientes pi ON pi.id_ingrediente = i.id_ingrediente
       SET i.stock_actual = i.stock_actual - (pi.cantidad_requerida * NEW.cantidad)
     WHERE pi.id_pizza = NEW.id_pizza;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 2: trg_historial_precios
-- Registra en historial_precios cada vez que cambia el precio_base
-- de una pizza.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_historial_precios;

DELIMITER $$
CREATE TRIGGER trg_historial_precios
BEFORE UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios (id_pizza, precio_anterior, precio_nuevo)
        VALUES (OLD.id_pizza, OLD.precio_base, NEW.precio_base);
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 3: trg_repartidor_ocupado
-- Al asignar un repartidor a un nuevo domicilio, lo marca como
-- 'No disponible'.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_repartidor_ocupado;

DELIMITER $$
CREATE TRIGGER trg_repartidor_ocupado
AFTER INSERT ON domicilios
FOR EACH ROW
BEGIN
    IF NEW.id_repartidor IS NOT NULL THEN
        UPDATE repartidores
           SET estado = 'No disponible'
         WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 4: trg_pedido_entregado
-- Cuando se registra hora_entrega en un domicilio:
--   a) libera al repartidor (queda 'Disponible')
--   b) llama al procedimiento que marca el pedido como 'Entregado'
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_pedido_entregado;

DELIMITER $$
CREATE TRIGGER trg_pedido_entregado
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    IF NEW.hora_entrega IS NOT NULL AND OLD.hora_entrega IS NULL THEN
        IF NEW.id_repartidor IS NOT NULL THEN
            UPDATE repartidores
               SET estado = 'Disponible'
             WHERE id_repartidor = NEW.id_repartidor;
        END IF;

        CALL sp_marcar_pedido_entregado(NEW.id_pedido);
    END IF;
END$$
DELIMITER ;


-- ---------------------------------------------------------------------
-- TRIGGER 5: trg_actualizar_total_detalle
-- Recalcula automáticamente pedidos.total cada vez que se agrega
-- una pizza al pedido (pedido_detalle).
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_actualizar_total_detalle;

DELIMITER $$
CREATE TRIGGER trg_actualizar_total_detalle
AFTER INSERT ON pedido_detalle
FOR EACH ROW
BEGIN
    UPDATE pedidos
       SET total = fn_calcular_total_pedido(NEW.id_pedido)
     WHERE id_pedido = NEW.id_pedido;
END$$
DELIMITER ;

-- ---------------------------------------------------------------------
-- TRIGGER 6: trg_actualizar_total_envio
-- Recalcula pedidos.total cuando se registra o cambia el costo_envio
-- de un domicilio.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_actualizar_total_envio;

DELIMITER $$
CREATE TRIGGER trg_actualizar_total_envio
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    IF NOT (NEW.costo_envio <=> OLD.costo_envio) THEN
        UPDATE pedidos
           SET total = fn_calcular_total_pedido(NEW.id_pedido)
         WHERE id_pedido = NEW.id_pedido;
    END IF;
END$$
DELIMITER ;