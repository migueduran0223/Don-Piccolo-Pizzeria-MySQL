-- =====================================================================
-- Archivo: triggers.sql
-- Proyecto: Pizzería Don Piccolo
-- Descripción: Triggers para control de inventario, auditoría de precios 
--              y gestión automática de disponibilidad de repartidores.
-- =====================================================================

USE pizzeria_piccolo;

-- Cambiar delimitador temporalmente para la creación de triggers
DELIMITER //

-- ---------------------------------------------------------------------
-- 1. Trigger: trg_actualizar_stock_ingredientes
-- Requerimiento funcional: Trigger de actualización automática de stock 
-- de ingredientes cuando se realiza un pedido (al insertar en detalle_pedido).
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_actualizar_stock_ingredientes//
CREATE TRIGGER trg_actualizar_stock_ingredientes
AFTER INSERT ON detalle_pedido
FOR EACH ROW
BEGIN
    -- Descontar del stock actual de ingredientes según la cantidad de pizzas pedidas
    UPDATE ingredientes i
    JOIN pizza_ingredientes pi ON i.id_ingrediente = pi.id_ingrediente
    SET i.stock_actual = i.stock_actual - (pi.cantidad_necesaria * NEW.cantidad)
    WHERE pi.id_pizza = NEW.id_pizza;
END//


-- ---------------------------------------------------------------------
-- 2. Trigger: trg_auditoria_precios_pizza
-- Requerimiento funcional: Trigger de auditoría que registre en una tabla 
-- historial_precios cada vez que se modifique el precio de una pizza.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_auditoria_precios_pizza//
CREATE TRIGGER trg_auditoria_precios_pizza
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    -- Verificar si realmente hubo un cambio en el precio base
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios (id_pizza, precio_anterior, precio_nuevo, fecha_modificacion)
        VALUES (OLD.id_pizza, OLD.precio_base, NEW.precio_base, NOW());
    END IF;
END//


-- ---------------------------------------------------------------------
-- 3. Trigger: trg_liberar_repartidor
-- Requerimiento funcional: Trigger para marcar repartidor como “disponible” 
-- nuevamente cuando termina un domicilio (al actualizar hora_entrega).
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_liberar_repartidor//
CREATE TRIGGER trg_liberar_repartidor
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    -- Si antes no tenía hora de entrega y ahora se le asigna (se completa el domicilio)
    IF OLD.hora_entrega IS NULL AND NEW.hora_entrega IS NOT NULL THEN
        UPDATE repartidores
        SET estado = 'disponible'
        WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END//

-- Restaurar el delimitador por defecto
DELIMITER ;