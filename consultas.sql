-- =====================================================================
-- Archivo: consultas.sql
-- Proyecto: Pizzería Don Piccolo
-- Descripción: Consultas SQL complejas solicitadas en los requerimientos 
--              (JOIN, subconsultas, operadores, agregaciones y filtros).
-- =====================================================================

USE pizzeria_piccolo;

-- ---------------------------------------------------------------------
-- 1. Clientes con pedidos entre dos fechas
-- Requerimiento funcional: Clientes con pedidos entre dos fechas (BETWEEN).
-- ---------------------------------------------------------------------
SELECT DISTINCT 
    c.nombre, 
    c.telefono, 
    p.id_pedido, 
    p.fecha_hora, 
    p.total
FROM clientes c 
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.fecha_hora BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59';


-- ---------------------------------------------------------------------
-- 2. Pizzas más vendidas
-- Requerimiento funcional: Pizzas más vendidas (GROUP BY y COUNT/SUM).
-- Omitiendo pedidos cancelados.
-- ---------------------------------------------------------------------
SELECT 
    pi.nombre, 
    pi.tamano, 
    SUM(dp.cantidad) AS unidades_vendidas
FROM detalle_pedido dp 
JOIN pizzas pi ON pi.id_pizza = dp.id_pizza 
JOIN pedidos p ON p.id_pedido = dp.id_pedido
WHERE p.estado <> 'cancelado' 
GROUP BY pi.id_pizza, pi.nombre, pi.tamano 
ORDER BY unidades_vendidas DESC;


-- ---------------------------------------------------------------------
-- 3. Pedidos por repartidor
-- Requerimiento funcional: Pedidos por repartidor (JOIN).
-- ---------------------------------------------------------------------
SELECT 
    r.nombre AS repartidor, 
    p.id_pedido, 
    p.estado, 
    d.hora_salida, 
    d.hora_entrega
FROM repartidores r 
JOIN domicilios d ON d.id_repartidor = r.id_repartidor 
JOIN pedidos p ON p.id_pedido = d.id_pedido
ORDER BY r.nombre, p.fecha_hora;


-- ---------------------------------------------------------------------
-- 4. Promedio de entrega por zona
-- Requerimiento funcional: Promedio de entrega por zona (AVG y JOIN).
-- Nota: Adaptado para campos DATETIME utilizando TIMEDIFF y TIME_TO_SEC 
-- para mantener consistencia con el archivo de vistas.
-- ---------------------------------------------------------------------
SELECT 
    r.zona_asignada, 
    ROUND(AVG(CASE 
        WHEN d.hora_salida IS NOT NULL AND d.hora_entrega IS NOT NULL 
        THEN TIME_TO_SEC(TIMEDIFF(d.hora_entrega, d.hora_salida)) / 60 
    END), 2) AS promedio_minutos
FROM domicilios d 
JOIN repartidores r ON r.id_repartidor = d.id_repartidor
WHERE d.hora_salida IS NOT NULL AND d.hora_entrega IS NOT NULL 
GROUP BY r.zona_asignada;


-- ---------------------------------------------------------------------
-- 5. Clientes que gastaron más de un monto
-- Requerimiento funcional: Clientes que gastaron más de un monto (HAVING).
-- ---------------------------------------------------------------------
SELECT 
    c.nombre, 
    SUM(p.total) AS total_gastado 
FROM clientes c 
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.estado <> 'cancelado' 
GROUP BY c.id_cliente, c.nombre 
HAVING SUM(p.total) > 100000;


-- ---------------------------------------------------------------------
-- 6. Búsqueda por coincidencia parcial de nombre de pizza
-- Requerimiento funcional: Búsqueda por coincidencia parcial (LIKE).
-- ---------------------------------------------------------------------
SELECT * 
FROM pizzas 
WHERE nombre LIKE '%pollo%';


-- ---------------------------------------------------------------------
-- 7. Clientes frecuentes (más de cinco pedidos en el mes actual)
-- Requerimiento funcional: Subconsulta para obtener clientes frecuentes.
-- ---------------------------------------------------------------------
SELECT 
    c.id_cliente, 
    c.nombre 
FROM clientes c 
WHERE c.id_cliente IN (
    SELECT p.id_cliente 
    FROM pedidos p 
    WHERE YEAR(p.fecha_hora) = YEAR(CURDATE()) 
      AND MONTH(p.fecha_hora) = MONTH(CURDATE())
      AND p.estado <> 'cancelado' 
    GROUP BY p.id_cliente 
    HAVING COUNT(*) > 5
);


-- ---------------------------------------------------------------------
-- PRUEBAS DE FUNCIONES Y PROCEDIMIENTOS (Ejecutar de manera individual)
-- ---------------------------------------------------------------------
-- SELECT calcular_total_pedido(1);
-- SELECT calcular_ganancia_neta_diaria(CURDATE());
-- CALL registrar_entrega(1, NOW());