-- create_tables.sql
-- Sistema de Gestión de Competiciones Deportivas
-- MySQL 8.0+ | InnoDB | UTF-8MB4

-- ====================================================================
-- CONFIGURACIÓN
-- ====================================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ====================================================================
-- TABLAS PRINCIPALES
-- ====================================================================

-- ATLETA
CREATE TABLE IF NOT EXISTS atleta (
    id_atleta         INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    fecha_nacimiento  DATE NOT NULL CHECK (fecha_nacimiento <= CURDATE()),
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
    fecha             DATE NOT NULL CHECK (fecha >= CURDATE()),
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
    -- CORRECCIÓN: Campo estándar (no Generated) para ser actualizado por Triggers
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

-- ====================================================================
-- ÍNDICES (Optimización de Consultas)
-- ====================================================================
CREATE INDEX idx_atleta_nombre ON atleta(nombre);
CREATE INDEX idx_atleta_apellido ON atleta(apellido);
CREATE INDEX idx_categoria_nombre ON categoria(nombre);
CREATE INDEX idx_competicion_fecha ON competicion(fecha);
CREATE INDEX idx_competicion_lugar ON competicion(lugar);
CREATE INDEX idx_inscripcion_competicion ON inscripcion(id_competicion);
CREATE INDEX idx_inscripcion_categoria ON inscripcion(id_categoria);
CREATE INDEX idx_inscripcion_posicion ON inscripcion(posicion_final);
CREATE INDEX idx_juez_nombre ON juez(nombre);
CREATE INDEX idx_puntuacion_inscripcion ON puntuacion(id_inscripcion);

-- ====================================================================
-- COMENTARIOS DE DOCUMENTACIÓN
-- ====================================================================
ALTER TABLE atleta COMMENT = 'Almacena información personal de los atletas';
ALTER TABLE categoria COMMENT = 'Define categorías de competición por altura y peso';
ALTER TABLE competicion COMMENT = 'Registra eventos deportivos';
ALTER TABLE inscripcion COMMENT = 'Registra la participación de atletas en competiciones';
ALTER TABLE juez COMMENT = 'Almacena información de los jueces evaluadores';
ALTER TABLE puntuacion COMMENT = 'Registra rankings otorgados por jueces a inscripciones';
ALTER TABLE inscripcion MODIFY COLUMN puntuacion_total INT COMMENT 'Campo calculado: suma de rankings (Actualizado por triggers)';

-- ====================================================================
-- RESTAURAR CONFIGURACIÓN
-- ====================================================================
SET FOREIGN_KEY_CHECKS = 1;