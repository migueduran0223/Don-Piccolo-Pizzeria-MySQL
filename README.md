Pizzería Don Piccolo 🍕

Este repositio contiene la estructura y desarrollo de una base de datos, para resolver la problématica de registro de pedidos y domicilios, ya que todo lo hacen de manera manual y esto les trae retrasos y por ende insatisfacción de los clientes

la lógica está programada en (database, funciones, triggers, vistas y consultas) para la buena práctica de la base de datos

El proyecto está modularizado en cinco scripts principales para garantizar el orden, la seguridad y la correcta compilación de las dependencias:

database: Aquí es donde hacemos la creación de la base de datos y el esquema conformado por 9 tablas juntos con sus llaves primarias, foráneas y restricciones

funciones: Funciones almacenadas y procedimientos de negocio para el cálculo dinámico de totales de pedidos (incluyendo subtotal, envío e IVA), cálculo de ganancias netas y la gestión de entregas.

triggers: Aquí se encuentran disparadores orientados al control automático de inventario (descuento de stock), auditoría de cambios de precios en el historial y liberación automática de repartidores tras finalizar un domicilio. 

vistas: son las Vistas analíticas optimizadas para la consulta rápida de resúmenes de clientes, desempeño de repartidores e identificación de insumos con stock bajo.

consultas: Conjunto de consultas complejas basadas en requerimientos operativos

Habiendo organizado nuestros archivos, procedemos a la busqueda de entidades relacionadas al modelo relacional.

Contamos con 9 entidades, las cuales son las siguientes

Clientes: Almacena la información de contacto de los compradores.
Repartidores: Gestiona el personal de entrega, su zona asignada y estado operativo (disponible / no disponible).
Ingredientes: Controla el inventario de insumos, stock actual, stock mínimo y unidad de medida.
Pizzas: Catálogo de productos con tamaños, tipos y precios base.
Pizza_Ingredientes: Tabla intermedia (N:M) que define la receta exacta y cantidad de insumos que consume cada pizza.
Pedidos:Registro central de órdenes de compra, métodos de pago, estados y valores totales.
Detalle_Pedido: Detalle de las pizzas solicitadas por orden y sus subtotales.
Domicilios: Enlaza un pedido único con su repartidor asignado, distancias, costos de envío y marcas de tiempo de salida/entrega.
Historial_Precios:Tabla de auditoría que registra automáticamente los cambios de precios en las pizzas.

Teniendo claro lo que contiene nuestro proyecto se darán los ejemplos de consultas:

1. Filtrado de clientes por rango de fechas (BETWEEN): Permite consultar los pedidos realizados por los clientes dentro de un periodo específico:SQLSELECT DISTINCT 

   c.nombre, 
    c.telefono, 
    p.id_pedido, 
    p.fecha_hora, 
    p.total
FROM clientes c 
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.fecha_hora BETWEEN '2026-09-01 00:00:00' AND '2026-09-30 23:59:59';


2. Pizzas más vendidas (GROUP BY y agregación): Obtiene un ranking de las pizzas con mayor demanda comercial, omitiendo las órdenes canceladas:   SQLSELECT 

    pi.nombre, 
    pi.tamano, 
    SUM(dp.cantidad) AS unidades_vendidas
FROM detalle_pedido dp 
JOIN pizzas pi ON pi.id_pizza = dp.id_pizza 
JOIN pedidos p ON p.id_pedido = dp.id_pedido
WHERE p.estado <> 'cancelado' 
GROUP BY pi.id_pizza, pi.nombre, pi.tamano 
ORDER BY unidades_vendidas DESC;


3. Filtrado por umbrales de gasto (HAVING): Identifica a los clientes que han acumulado un nivel de gasto superior a un monto determinado en sus pedidos:   SQLSELECT 

   c.nombre, 
    SUM(p.total) AS total_gastado 
FROM clientes c 
JOIN pedidos p ON p.id_cliente = c.id_cliente
WHERE p.estado <> 'cancelado' 
GROUP BY c.id_cliente, c.nombre 
HAVING SUM(p.total) > 100000;

4. Búsqueda por coincidencia parcial (LIKE): Facilita la localización de productos en el catálogo mediante fragmentos de texto:   SQLSELECT * 

FROM pizzas 
WHERE nombre LIKE '%pollo%';

Como último punto, veremos como ejecutar de manera correcta el proyecto

Primeramente ejecutamos database.sql, seguido funciones.sql, posteriormente triggers.sql, ya con esto, abrimos vistas la ejecutamos, y finalizamos con consultas.sql, querramos ejecutarlo en su totalidad o consulta por consulta para sus comprobaciones 

Con esto damos por terminada nuestra base de datos relacional Pizzeria_Piccolo, su correcto funcionamiento y óptima solución a los problemas que poseía con su pizzería
