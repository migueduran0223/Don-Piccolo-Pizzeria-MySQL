-- =====================================================================
-- Archivo: funciones.sql
-- Proyecto: Pizzería Don Piccolo
-- Descripción: Funciones y Procedimientos Almacenados del negocio 
--              (Cálculo de totales, ganancias y gestión de entregas).
-- =====================================================================

USE pizzeria_piccolo;

-- Cambiar delimitador temporalmente para funciones y procedimientos complejos
DELIMITER //

-- ---------------------------------------------------------------------
-- 1. Función: calcular_total_pedido
-- Requerimiento funcional: Función para calcular el total de un pedido 
-- (sumando precios de pizzas + costo de envío + IVA del 19%).
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS calcular_total_pedido//
CREATE FUNCTION calcular_total_pedido(p_id_pedido INT) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_subtotal_pizzas DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_costo_envio DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_subtotal_general DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_total_final DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_iva DECIMAL(10,2) DEFAULT 0.00;

    -- 1. Sumar el valor de todas las pizzas del detalle del pedido
    SELECT COALESCE(SUM(subtotal), 0.00)
    INTO v_subtotal_pizzas
    FROM detalle_pedido
    WHERE id_pedido = p_id_pedido;

    -- 2. Obtener el costo de envío asociado al domicilio del pedido (si existe)
    SELECT COALESCE(costo_envio, 0.00)
    INTO v_costo_envio
    FROM domicilios
    WHERE id_pedido = p_id_pedido;

    -- 3. Calcular subtotal antes de impuestos (Pizzas + Envío)
    SET v_subtotal_general = v_subtotal_pizzas + v_costo_envio;

    -- 4. Aplicar IVA del 19% sobre las pizzas (o sobre el total según política; aquí aplicamos sobre pizzas o subtotal general)
    -- Asumiremos IVA estándar del 19% sobre los productos y servicios gravados:
    SET v_iva = v_subtotal_pizzas * 0.19;

    -- 5. Total final
    SET v_total_final = v_subtotal_general + v_iva;

    RETURN v_total_final;
END//


-- ---------------------------------------------------------------------
-- 2. Función: calcular_ganancia_neta_diaria
-- Requerimiento funcional: Función para calcular la ganancia neta diaria 
-- (ventas - costos de ingredientes de los pedidos entregados/realizados).
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS calcular_ganancia_neta_diaria//
CREATE FUNCTION calcular_ganancia_neta_diaria(p_fecha DATE) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_ventas DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_total_costos_ingredientes DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_ganancia_neta DECIMAL(10,2) DEFAULT 0.00;

    -- 1. Calcular total de ventas del día (excluyendo cancelados)
    SELECT COALESCE(SUM(p.total), 0.00)
    INTO v_total_ventas
    FROM pedidos p
    WHERE DATE(p.fecha_hora) = p_fecha
      AND p.estado <> 'cancelado';

    -- 2. Calcular el costo total de los ingredientes gastados en los pedidos de ese día
    SELECT COALESCE(SUM(dp.cantidad * pi_ing.cantidad_necesaria * 
        (SELECT COALESCE(AVG(ing_cost.stock_actual), 0) FROM ingredientes ing_cost WHERE ing_cost.id_ingrediente = pi_ing.id_ingrediente) -- Estimación o costo base si existiera columna precio
    ), 0.00) 
    -- Nota: Como la tabla ingredientes maneja stock, para el costo puro de ingredientes idealmente se usaría un campo 'costo_unitario'. 
    -- Suponiendo un costo estándar o simplificado para el balance del ejercicio:
    INTO v_total_costos_ingredientes
    FROM pedidos p
    JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
    JOIN pizza_ingredientes pi_ing ON dp.id_pizza = pi_ing.id_pizza
    WHERE DATE(p.fecha_hora) = p_fecha
      AND p.estado <> 'cancelado';
      
    -- Ajuste simplificado y robusto para proyectos junior basados en insumos:
    -- Si no se tiene un costo unitario estricto en ingredientes, calculamos basándonos en la proporción de stock o devolvemos la diferencia estimada.
    -- Vamos a calcular la ganancia restando los costos directos asociados:
    SET v_ganancia_neta = v_total_ventas - (v_total_ventas * 0.35); -- Estimación estándar de costo de materia prima en pizzerías (35% COGS) o cálculo por ingrediente.
    -- O mejor aún, hagamos una consulta limpia basada en la cantidad de ingredientes restados. 
    -- Usemos una aproximación segura con base en los registros de consumo:
    
    SELECT COALESCE(SUM(dp.cantidad * pi_ing.cantidad_necesaria * 500), 0.00) -- Asumiendo un costo unitario estimado por unidad de ingrediente de referencia si aplica,
    INTO v_total_costos_ingredientes                                          -- o bien calculándolo directamente de las tablas relacionadas.
    FROM pedidos p
    JOIN detalle_pedido dp ON p.id_pedido = dp.id_pedido
    JOIN pizza_ingredientes pi_ing ON dp.id_pizza = pi_ing.id_pizza
    WHERE DATE(p.fecha_hora) = p_fecha AND p.estado <> 'cancelado';

    SET v_ganancia_neta = v_total_ventas - v_total_costos_ingredientes;

    RETURN v_ganancia_neta;
END//


-- ---------------------------------------------------------------------
-- 3. Procedimiento: registrar_entrega
-- Requerimiento funcional: Procedimiento para cambiar automáticamente 
-- el estado del pedido a “entregado” cuando se registre la hora de entrega.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS registrar_entrega//
CREATE PROCEDURE registrar_entrega(
    IN p_id_pedido INT,
    IN p_hora_entrega DATETIME
)
BEGIN
    -- Actualizar la hora de entrega en la tabla domicilios
    UPDATE domicilios 
    SET hora_entrega = p_hora_entrega
    WHERE id_pedido = p_id_pedido;

    -- Actualizar el estado del pedido a 'entregado'
    UPDATE pedidos 
    SET estado = 'entregado'
    WHERE id_pedido = p_id_pedido;
    
    -- Nota: El trigger correspondiente se encargará de liberar al repartidor automáticamente.
END//

-- Restaurar el delimitador por defecto
DELIMITER ;