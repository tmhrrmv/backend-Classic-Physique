SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ====================================================================
-- SELECCIÓN DE BASE DE DATOS
-- ====================================================================
CREATE DATABASE IF NOT EXISTS competencia_db 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE competencia_db;

-- ====================================================================
-- TABLAS PRINCIPALES
-- ====================================================================

-- ATLETA
CREATE TABLE IF NOT EXISTS atleta (
    id_atleta         INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    -- Se elimina CHECK con CURDATE()
    fecha_nacimiento  DATE NOT NULL, 
    nacionalidad      VARCHAR(50) NOT NULL CHECK (CHAR_LENGTH(TRIM(nacionalidad)) >= 2),
    fecha_creacion    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CATEGORIA
CREATE TABLE IF NOT EXISTS categoria (
    id_categoria               INT AUTO_INCREMENT PRIMARY KEY,
    nombre                     VARCHAR(50) NOT NULL UNIQUE CHECK (CHAR_LENGTH(TRIM(nombre)) >= 2),
    altura_min                 DECIMAL(5,2) NOT NULL CHECK (altura_min > 0),
    altura_max                 DECIMAL(5,2) NOT NULL CHECK (altura_max > altura_min),
    peso_maximo_permitido      DECIMAL(5,2) NOT NULL CHECK (peso_maximo_permitido > 0),
    fecha_creacion             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- COMPETICION
CREATE TABLE IF NOT EXISTS competicion (
    id_competicion    INT AUTO_INCREMENT PRIMARY KEY,
    nombre_evento     VARCHAR(200) NOT NULL CHECK (CHAR_LENGTH(TRIM(nombre_evento)) >= 3),
    -- Se elimina CHECK con CURDATE()
    fecha             DATE NOT NULL, 
    lugar             VARCHAR(200) NOT NULL CHECK (CHAR_LENGTH(TRIM(lugar)) >= 2),
    fecha_creacion    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- JUEZ
CREATE TABLE IF NOT EXISTS juez (
    id_juez           INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    licencia          VARCHAR(50) NOT NULL UNIQUE CHECK (CHAR_LENGTH(TRIM(licencia)) >= 3),
    fecha_creacion    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABLA INTERMEDIA: INSCRIPCION
-- ====================================================================
CREATE TABLE IF NOT EXISTS inscripcion (
    id_inscripcion        INT AUTO_INCREMENT PRIMARY KEY,
    id_atleta             INT NOT NULL,
    id_competicion        INT NOT NULL,
    id_categoria          INT NOT NULL,
    numero_dorsal         INT UNIQUE CHECK (numero_dorsal > 0),
    peso_registro         DECIMAL(5,2) CHECK (peso_registro > 0),
    estatura_registro     DECIMAL(5,2) CHECK (estatura_registro > 0),
    puntuacion_total      INT DEFAULT 0,
    posicion_final        INT CHECK (posicion_final >= 1),
    fecha_creacion        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_inscripcion_atleta FOREIGN KEY (id_atleta) REFERENCES atleta(id_atleta) ON DELETE CASCADE,
    CONSTRAINT fk_inscripcion_competicion FOREIGN KEY (id_competicion) REFERENCES competicion(id_competicion) ON DELETE CASCADE,
    CONSTRAINT fk_inscripcion_categoria FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
    CONSTRAINT inscripcion_unica UNIQUE (id_atleta, id_competicion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABLA DE PUNTUACIONES
-- ====================================================================
CREATE TABLE IF NOT EXISTS puntuacion (
    id_puntuacion    INT AUTO_INCREMENT PRIMARY KEY,
    id_inscripcion   INT NOT NULL,
    id_juez          INT NOT NULL,
    ranking_otorgado INT NOT NULL CHECK (ranking_otorgado >= 1),
    fecha_creacion   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_puntuacion_inscripcion FOREIGN KEY (id_inscripcion) REFERENCES inscripcion(id_inscripcion) ON DELETE CASCADE,
    CONSTRAINT fk_puntuacion_juez FOREIGN KEY (id_juez) REFERENCES juez(id_juez) ON DELETE RESTRICT,
    CONSTRAINT juez_unico_por_inscripcion UNIQUE (id_inscripcion, id_juez)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
