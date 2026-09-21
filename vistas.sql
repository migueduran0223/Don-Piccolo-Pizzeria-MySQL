USE pizzeria_piccolo;

-- ---------------------------------------------------------------------
-- 1. Vista de resumen de pedidos por cliente
-- Requerimiento funcional: Vista de resumen de pedidos por cliente 
-- (nombre del cliente, cantidad de pedidos, total gastado).
-- Omitiendo los pedidos cancelados en el cálculo del gasto.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_resumen_pedidos_cliente AS
SELECT 
    c.id_cliente, 
    c.nombre, 
    COUNT(p.id_pedido) AS cantidad_pedidos,
    COALESCE(SUM(CASE WHEN p.estado <> 'cancelado' THEN p.total ELSE 0 END), 0) AS total_gastado
FROM clientes c 
LEFT JOIN pedidos p ON p.id_cliente = c.id_cliente 
GROUP BY c.id_cliente, c.nombre;


-- ---------------------------------------------------------------------
-- 2. Vista de desempeño de repartidores
-- Requerimiento funcional: Vista de desempeño de repartidores 
-- (número de entregas, tiempo promedio, zona).
-- Nota: Adaptado para campos DATETIME utilizando TIMEDIFF para calcular 
-- la diferencia de tiempo completa y TIME_TO_SEC para llevarla a minutos.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_desempeno_repartidores AS
SELECT 
    r.id_repartidor, 
    r.nombre, 
    r.zona_asignada, 
    COUNT(d.id_domicilio) AS numero_entregas,
    ROUND(AVG(CASE 
        WHEN d.hora_entrega IS NOT NULL AND d.hora_salida IS NOT NULL
        THEN TIME_TO_SEC(TIMEDIFF(d.hora_entrega, d.hora_salida)) / 60 
    END), 2) AS minutos_promedio_entrega
FROM repartidores r 
LEFT JOIN domicilios d ON d.id_repartidor = r.id_repartidor
GROUP BY r.id_repartidor, r.nombre, r.zona_asignada;


-- ---------------------------------------------------------------------
-- 3. Vista de stock de ingredientes por debajo del mínimo permitido
-- Requerimiento funcional: Vista de stock de ingredientes 
-- por debajo del mínimo permitido para control de inventario.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_stock_bajo AS
SELECT 
    id_ingrediente, 
    nombre, 
    stock_actual, 
    stock_minimo, 
    unidad_medida
FROM ingredientes 
WHERE stock_actual <= stock_minimo;
