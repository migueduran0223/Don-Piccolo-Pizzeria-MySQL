-- =====================================================================
-- Archivo: database.sql
-- Proyecto: Pizzería Don Piccolo
-- Descripción: Creación de la base de datos y tablas relacionales 
--              con sus respectivas llaves primarias y foráneas.
-- =====================================================================

DROP DATABASE IF EXISTS pizzeria_piccolo;
CREATE DATABASE pizzeria_piccolo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pizzeria_piccolo;

-- ---------------------------------------------------------------------
-- 1. Tabla: clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(150) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. Tabla: repartidores
-- ---------------------------------------------------------------------
CREATE TABLE repartidores (
    id_repartidor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    zona_asignada VARCHAR(50) NOT NULL,
    estado ENUM('disponible', 'no disponible') DEFAULT 'disponible'
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. Tabla: ingredientes
-- ---------------------------------------------------------------------
CREATE TABLE ingredientes (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    stock_actual DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock_minimo DECIMAL(10,2) NOT NULL DEFAULT 5.00,
    unidad_medida VARCHAR(20) NOT NULL -- Ej: gramos, unidades, mililitros
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. Tabla: pizzas
-- ---------------------------------------------------------------------
CREATE TABLE pizzas (
    id_pizza INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tamano ENUM('personal', 'mediana', 'familiar', 'gigante') NOT NULL,
    precio_base DECIMAL(10,2) NOT NULL,
    tipo ENUM('vegetariana', 'especial', 'clásica') NOT NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. Tabla intermedia: pizza_ingredientes (Relación N:M)
-- ---------------------------------------------------------------------
CREATE TABLE pizza_ingredientes (
    id_pizza INT,
    id_ingrediente INT,
    cantidad_necesaria DECIMAL(10,2) NOT NULL, -- Cantidad que consume esta pizza por porción
    PRIMARY KEY (id_pizza, id_ingrediente),
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza) ON DELETE CASCADE,
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes(id_ingrediente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. Tabla: pedidos
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago ENUM('efectivo', 'tarjeta', 'app') NOT NULL,
    estado ENUM('pendiente', 'en preparación', 'entregado', 'cancelado') DEFAULT 'pendiente',
    total DECIMAL(10,2) DEFAULT 0.00,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. Tabla intermedia: detalle_pedido (Pizzas solicitadas en el pedido)
-- ---------------------------------------------------------------------
CREATE TABLE detalle_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_pizza INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    subtotal DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. Tabla: domicilios
-- ---------------------------------------------------------------------
CREATE TABLE domicilios (
    id_domicilio INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL UNIQUE, -- Un pedido tiene un único domicilio asociado
    id_repartidor INT NOT NULL,
    hora_salida DATETIME NULL,
    hora_entrega DATETIME NULL,
    distancia_km DECIMAL(5,2) NOT NULL,
    costo_envio DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. Tabla: historial_precios (Para auditoría de cambios de precio)
-- ---------------------------------------------------------------------
CREATE TABLE historial_precios (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_pizza INT NOT NULL,
    precio_anterior DECIMAL(10,2) NOT NULL,
    precio_nuevo DECIMAL(10,2) NOT NULL,
    fecha_modificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pizza) REFERENCES pizzas(id_pizza) ON DELETE CASCADE
) ENGINE=InnoDB;