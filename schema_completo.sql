-- ============================================================
-- schema_completo.sql  (MySQL)
-- Versión unificada — equivale a ejecutar en orden:
--   1. create_tables.sql
--   2. triggers.sql
--   3. functions.sql
--   4. insert_data.sql
--
-- Ejecutar desde terminal:
--   mysql -u root -p < schema_completo.sql
-- ============================================================

-- ============================================================
-- ARCHIVO 1: create_tables.sql
-- Orden de ejecución: 1°
-- Base de datos: MySQL
-- ============================================================

-- PASO 0: Crear y seleccionar la base de datos
DROP DATABASE IF EXISTS gestion_competiciones;
CREATE DATABASE gestion_competiciones
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_spanish_ci;

USE gestion_competiciones;

-- -------------------------------------------------------
-- categoria: rangos válidos por categoría de competición
-- -------------------------------------------------------
CREATE TABLE categoria (
  id_categoria          INT           NOT NULL AUTO_INCREMENT,
  nombre                VARCHAR(100)  NOT NULL,
  altura_min            DECIMAL(5,2)  DEFAULT NULL,
  altura_max            DECIMAL(5,2)  DEFAULT NULL,
  peso_maximo_permitido DECIMAL(6,2)  DEFAULT NULL,
  PRIMARY KEY (id_categoria),
  UNIQUE KEY uq_categoria_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -------------------------------------------------------
-- competicion: cada evento es un registro independiente
-- -------------------------------------------------------
CREATE TABLE competicion (
  id_competicion INT          NOT NULL AUTO_INCREMENT,
  nombre_evento  VARCHAR(200) NOT NULL,
  fecha          DATE         DEFAULT NULL,
  lugar          VARCHAR(200) DEFAULT NULL,
  PRIMARY KEY (id_competicion),
  UNIQUE KEY uq_competicion (nombre_evento, fecha)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -------------------------------------------------------
-- atleta: datos de identidad fijos (no cambian entre eventos)
-- peso, estatura y categoría se registran por inscripción
-- -------------------------------------------------------
CREATE TABLE atleta (
  id_atleta        INT          NOT NULL AUTO_INCREMENT,
  nombre           VARCHAR(100) NOT NULL,
  apellido         VARCHAR(100) NOT NULL,
  fecha_nacimiento DATE         NOT NULL,
  nacionalidad     VARCHAR(10)  DEFAULT NULL,
  PRIMARY KEY (id_atleta),
  UNIQUE KEY uq_atleta (nombre, apellido, fecha_nacimiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -------------------------------------------------------
-- juez
-- -------------------------------------------------------
CREATE TABLE juez (
  id_juez  INT          NOT NULL AUTO_INCREMENT,
  nombre   VARCHAR(200) NOT NULL,
  licencia VARCHAR(50)  NOT NULL,
  PRIMARY KEY (id_juez),
  UNIQUE KEY uq_juez_licencia (licencia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -------------------------------------------------------
-- inscripcion: una fila por (atleta x evento)
--
--   * peso_registro y estatura_registro se toman en el
--     momento de inscribirse en ese evento concreto.
--   * id_categoria puede cambiar entre eventos.
--   * numero_dorsal se asigna por evento.
--   * UNIQUE (id_atleta, id_competicion) evita duplicados
--     dentro del mismo evento, pero permite al mismo atleta
--     aparecer en N eventos distintos con datos nuevos.
-- -------------------------------------------------------
CREATE TABLE inscripcion (
  id_inscripcion    INT          NOT NULL AUTO_INCREMENT,
  id_atleta         INT          NOT NULL,
  id_competicion    INT          NOT NULL,
  id_categoria      INT          DEFAULT NULL,
  numero_dorsal     INT          DEFAULT NULL,
  peso_registro     DECIMAL(6,2) DEFAULT NULL,
  estatura_registro DECIMAL(5,2) DEFAULT NULL,
  fecha_inscripcion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_inscripcion),
  UNIQUE KEY uq_atleta_evento (id_atleta, id_competicion),
  CONSTRAINT fk_insc_atleta      FOREIGN KEY (id_atleta)      REFERENCES atleta(id_atleta)           ON DELETE CASCADE,
  CONSTRAINT fk_insc_competicion FOREIGN KEY (id_competicion) REFERENCES competicion(id_competicion) ON DELETE CASCADE,
  CONSTRAINT fk_insc_categoria   FOREIGN KEY (id_categoria)   REFERENCES categoria(id_categoria)     ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- -------------------------------------------------------
-- puntuacion: nota de un juez sobre una inscripción concreta
-- -------------------------------------------------------
CREATE TABLE puntuacion (
  id_puntuacion    INT NOT NULL AUTO_INCREMENT,
  id_inscripcion   INT NOT NULL,
  id_juez          INT NOT NULL,
  ranking_otorgado INT DEFAULT NULL,
  PRIMARY KEY (id_puntuacion),
  UNIQUE KEY uq_puntuacion (id_inscripcion, id_juez),
  CONSTRAINT fk_punt_inscripcion FOREIGN KEY (id_inscripcion) REFERENCES inscripcion(id_inscripcion) ON DELETE CASCADE,
  CONSTRAINT fk_punt_juez        FOREIGN KEY (id_juez)        REFERENCES juez(id_juez)               ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- Índices para consultas frecuentes
CREATE INDEX idx_inscripcion_atleta      ON inscripcion(id_atleta);
CREATE INDEX idx_inscripcion_competicion ON inscripcion(id_competicion);
CREATE INDEX idx_puntuacion_inscripcion  ON puntuacion(id_inscripcion);


-- ============================================================
-- ARCHIVO 2: triggers.sql
-- Orden de ejecución: 2° (después de create_tables.sql)
-- Base de datos: MySQL
-- ============================================================


DROP TRIGGER IF EXISTS trg_validar_inscripcion_insert;
DROP TRIGGER IF EXISTS trg_validar_inscripcion_update;

DELIMITER $$

-- -------------------------------------------------------
-- Trigger: trg_validar_inscripcion_insert
-- Valida que peso y estatura sean coherentes con los
-- límites de la categoría elegida al inscribir un atleta.
-- -------------------------------------------------------
CREATE TRIGGER trg_validar_inscripcion_insert
BEFORE INSERT ON inscripcion
FOR EACH ROW
BEGIN
  DECLARE v_peso_max   DECIMAL(6,2);
  DECLARE v_altura_min DECIMAL(5,2);
  DECLARE v_altura_max DECIMAL(5,2);

  IF NEW.id_categoria IS NOT NULL THEN

    SELECT peso_maximo_permitido, altura_min, altura_max
      INTO v_peso_max, v_altura_min, v_altura_max
      FROM categoria
     WHERE id_categoria = NEW.id_categoria;

    IF NEW.peso_registro IS NOT NULL AND v_peso_max IS NOT NULL
       AND NEW.peso_registro > v_peso_max THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El peso del atleta supera el máximo permitido para la categoría';
    END IF;

    IF NEW.estatura_registro IS NOT NULL AND v_altura_min IS NOT NULL
       AND NEW.estatura_registro < v_altura_min THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La estatura del atleta es inferior al mínimo de la categoría';
    END IF;

    IF NEW.estatura_registro IS NOT NULL AND v_altura_max IS NOT NULL
       AND NEW.estatura_registro > v_altura_max THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La estatura del atleta supera el máximo de la categoría';
    END IF;

  END IF;
END$$

-- -------------------------------------------------------
-- Trigger: trg_validar_inscripcion_update
-- Aplica las mismas validaciones al actualizar una
-- inscripción (si se corrige categoría o datos físicos).
-- -------------------------------------------------------
CREATE TRIGGER trg_validar_inscripcion_update
BEFORE UPDATE ON inscripcion
FOR EACH ROW
BEGIN
  DECLARE v_peso_max   DECIMAL(6,2);
  DECLARE v_altura_min DECIMAL(5,2);
  DECLARE v_altura_max DECIMAL(5,2);

  IF NEW.id_categoria IS NOT NULL THEN

    SELECT peso_maximo_permitido, altura_min, altura_max
      INTO v_peso_max, v_altura_min, v_altura_max
      FROM categoria
     WHERE id_categoria = NEW.id_categoria;

    IF NEW.peso_registro IS NOT NULL AND v_peso_max IS NOT NULL
       AND NEW.peso_registro > v_peso_max THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El peso del atleta supera el máximo permitido para la categoría';
    END IF;

    IF NEW.estatura_registro IS NOT NULL AND v_altura_min IS NOT NULL
       AND NEW.estatura_registro < v_altura_min THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La estatura del atleta es inferior al mínimo de la categoría';
    END IF;

    IF NEW.estatura_registro IS NOT NULL AND v_altura_max IS NOT NULL
       AND NEW.estatura_registro > v_altura_max THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La estatura del atleta supera el máximo de la categoría';
    END IF;

  END IF;
END$$

DELIMITER ;


-- ============================================================
-- ARCHIVO 3: functions.sql
-- Orden de ejecución: 3° (después de triggers.sql)
-- Base de datos: MySQL
-- ============================================================


DROP PROCEDURE IF EXISTS inscribir_atleta;
DROP PROCEDURE IF EXISTS actualizar_datos_inscripcion;
DROP PROCEDURE IF EXISTS historial_atleta;
DROP PROCEDURE IF EXISTS atletas_sin_inscripcion_en_evento;

DELIMITER $$

-- -------------------------------------------------------
-- PROCEDURE: inscribir_atleta
--
-- Registra a un atleta en un evento con sus datos físicos
-- actuales (peso, estatura, categoría).
--
--   - Si el atleta no existe -> lo crea.
--   - Si ya está inscrito en ESE evento -> error claro.
--   - Si ya estuvo en OTROS eventos -> crea nueva inscripción
--     con los datos físicos nuevos (pueden ser distintos).
--
-- El trigger trg_validar_inscripcion_insert valida
-- automáticamente peso/estatura vs categoría.
-- -------------------------------------------------------
CREATE PROCEDURE inscribir_atleta(
  IN p_nombre             VARCHAR(100),
  IN p_apellido           VARCHAR(100),
  IN p_fecha_nacimiento   DATE,
  IN p_nacionalidad       VARCHAR(10),
  IN p_id_competicion     INT,
  IN p_id_categoria       INT,
  IN p_numero_dorsal      INT,
  IN p_peso_registro      DECIMAL(6,2),
  IN p_estatura_registro  DECIMAL(5,2)
)
BEGIN
  DECLARE v_id_atleta      INT DEFAULT NULL;
  DECLARE v_id_inscripcion INT DEFAULT NULL;
  DECLARE v_ya_inscrito    INT DEFAULT 0;

  IF p_id_competicion IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Debes indicar el evento (p_id_competicion) al inscribir un atleta';
  END IF;

  -- Crear atleta si no existe; si ya existe, ignorar
  INSERT IGNORE INTO atleta (nombre, apellido, fecha_nacimiento, nacionalidad)
  VALUES (p_nombre, p_apellido, p_fecha_nacimiento, p_nacionalidad);

  SELECT id_atleta INTO v_id_atleta
    FROM atleta
   WHERE nombre           = p_nombre
     AND apellido         = p_apellido
     AND fecha_nacimiento = p_fecha_nacimiento
   LIMIT 1;

  -- Verificar si ya está inscrito en ESTE evento
  SELECT COUNT(*) INTO v_ya_inscrito
    FROM inscripcion
   WHERE id_atleta      = v_id_atleta
     AND id_competicion = p_id_competicion;

  IF v_ya_inscrito > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'El atleta ya está inscrito en este evento. Usa actualizar_datos_inscripcion() para corregir sus datos.';
  END IF;

  -- Crear inscripción con los datos físicos actuales
  -- (el trigger validará peso/estatura vs categoría)
  INSERT INTO inscripcion
    (id_atleta, id_competicion, id_categoria, numero_dorsal, peso_registro, estatura_registro)
  VALUES
    (v_id_atleta, p_id_competicion, p_id_categoria, p_numero_dorsal, p_peso_registro, p_estatura_registro);

  SET v_id_inscripcion = LAST_INSERT_ID();

  SELECT
    v_id_atleta      AS out_id_atleta,
    v_id_inscripcion AS out_id_inscripcion,
    'Inscripción creada correctamente' AS mensaje;
END$$


-- -------------------------------------------------------
-- PROCEDURE: actualizar_datos_inscripcion
--
-- Corrige los datos físicos de una inscripción ya existente.
-- Usa COALESCE para actualizar solo los campos que se pasen.
-- -------------------------------------------------------
CREATE PROCEDURE actualizar_datos_inscripcion(
  IN p_id_inscripcion     INT,
  IN p_id_categoria       INT,
  IN p_numero_dorsal      INT,
  IN p_peso_registro      DECIMAL(6,2),
  IN p_estatura_registro  DECIMAL(5,2)
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inscripcion WHERE id_inscripcion = p_id_inscripcion) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No existe una inscripción con ese id';
  END IF;

  -- El trigger trg_validar_inscripcion_update validará los nuevos datos
  UPDATE inscripcion SET
    id_categoria      = COALESCE(p_id_categoria,      id_categoria),
    numero_dorsal     = COALESCE(p_numero_dorsal,     numero_dorsal),
    peso_registro     = COALESCE(p_peso_registro,     peso_registro),
    estatura_registro = COALESCE(p_estatura_registro, estatura_registro)
  WHERE id_inscripcion = p_id_inscripcion;

  SELECT 'Inscripción actualizada correctamente' AS mensaje, ROW_COUNT() AS filas_afectadas;
END$$


-- -------------------------------------------------------
-- PROCEDURE: historial_atleta
--
-- Muestra el historial completo de un atleta en todos los
-- eventos en que ha participado, con los datos físicos
-- que tenía en cada momento.
-- -------------------------------------------------------
CREATE PROCEDURE historial_atleta(
  IN p_id_atleta INT
)
BEGIN
  SELECT
    a.nombre                   AS nombre_atleta,
    a.apellido                 AS apellido_atleta,
    c.nombre_evento,
    c.fecha                    AS fecha_evento,
    cat.nombre                 AS categoria,
    i.numero_dorsal,
    i.peso_registro            AS peso_en_ese_evento,
    i.estatura_registro        AS estatura_en_ese_evento,
    i.fecha_inscripcion
  FROM inscripcion i
  JOIN atleta      a   ON a.id_atleta      = i.id_atleta
  JOIN competicion c   ON c.id_competicion = i.id_competicion
  LEFT JOIN categoria cat ON cat.id_categoria = i.id_categoria
  WHERE i.id_atleta = p_id_atleta
  ORDER BY c.fecha;
END$$


-- -------------------------------------------------------
-- PROCEDURE: atletas_sin_inscripcion_en_evento
--
-- Lista atletas que NO están inscritos en un evento concreto.
-- -------------------------------------------------------
CREATE PROCEDURE atletas_sin_inscripcion_en_evento(
  IN p_id_competicion INT
)
BEGIN
  SELECT
    a.id_atleta,
    a.nombre,
    a.apellido,
    a.fecha_nacimiento,
    a.nacionalidad
  FROM atleta a
  WHERE NOT EXISTS (
    SELECT 1 FROM inscripcion i
     WHERE i.id_atleta      = a.id_atleta
       AND i.id_competicion = p_id_competicion
  )
  ORDER BY a.apellido, a.nombre;
END$$

DELIMITER ;


-- ============================================================
-- ARCHIVO 4: insert_data.sql
-- Orden de ejecución: 4° (después de functions.sql)
-- Base de datos: MySQL
-- ============================================================


-- -------------------------------------------------------
-- Categorías
-- -------------------------------------------------------
INSERT IGNORE INTO categoria (nombre, altura_min, altura_max, peso_maximo_permitido)
VALUES
  ('Cadete',  1.40, 1.59,  60.00),
  ('Juvenil', 1.60, 1.75,  75.00),
  ('Senior',  1.76, 2.20, 120.00);

-- -------------------------------------------------------
-- Competiciones (eventos reales, uno por fecha)
-- -------------------------------------------------------
INSERT IGNORE INTO competicion (nombre_evento, fecha, lugar)
VALUES
  ('Torneo Apertura 2024',       '2024-03-10', 'Estadio Nacional'),
  ('Copa Ciudad de Madrid 2024', '2024-09-21', 'Centro Deportivo Municipal'),
  ('Torneo Apertura 2025',       '2025-03-09', 'Estadio Nacional'),
  ('Copa Ciudad de Madrid 2025', '2025-09-20', 'Centro Deportivo Municipal');

-- -------------------------------------------------------
-- Jueces
-- -------------------------------------------------------
INSERT IGNORE INTO juez (nombre, licencia)
VALUES
  ('Roberto Diaz', 'JUE-001'),
  ('Ana Martinez', 'JUE-002');

-- -------------------------------------------------------
-- Inscripciones por evento
--
-- Carlos Gomez:    2024 -> Cadete  (55 kg, 1.55 m)
--                  2025 -> Juvenil (63 kg, 1.62 m) [creció y cambió categoría]
-- Maria Rodriguez: mantiene Juvenil pero varía el peso
-- Lucas Fernandez: Senior en todos los eventos
-- Sofia Lopez:     se incorpora en 2025
-- -------------------------------------------------------

-- === TORNEO APERTURA 2024 ===
CALL inscribir_atleta('Carlos', 'Gomez',     '2005-04-12', 'ESP',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2024'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Cadete'),
  101, 55.50, 1.55);

CALL inscribir_atleta('Maria', 'Rodriguez',  '2004-08-22', 'MEX',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2024'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Juvenil'),
  102, 62.00, 1.68);

CALL inscribir_atleta('Lucas', 'Fernandez',  '2002-01-15', 'ARG',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2024'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Senior'),
  103, 85.00, 1.80);

-- === COPA CIUDAD DE MADRID 2024 ===
CALL inscribir_atleta('Carlos', 'Gomez',     '2005-04-12', 'ESP',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Copa Ciudad de Madrid 2024'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Cadete'),
  201, 56.00, 1.55);

CALL inscribir_atleta('Lucas', 'Fernandez',  '2002-01-15', 'ARG',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Copa Ciudad de Madrid 2024'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Senior'),
  202, 86.50, 1.80);

-- === TORNEO APERTURA 2025 ===
-- Carlos sube de categoría: Cadete -> Juvenil
CALL inscribir_atleta('Carlos', 'Gomez',     '2005-04-12', 'ESP',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2025'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Juvenil'),
  101, 63.00, 1.62);

CALL inscribir_atleta('Maria', 'Rodriguez',  '2004-08-22', 'MEX',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2025'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Juvenil'),
  102, 60.50, 1.68);

CALL inscribir_atleta('Lucas', 'Fernandez',  '2002-01-15', 'ARG',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2025'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Senior'),
  103, 87.00, 1.80);

-- Sofia se incorpora en 2025
CALL inscribir_atleta('Sofia', 'Lopez',      '2003-11-30', 'CHL',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Torneo Apertura 2025'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Juvenil'),
  104, 58.00, 1.65);

-- === COPA CIUDAD DE MADRID 2025 ===
CALL inscribir_atleta('Carlos', 'Gomez',     '2005-04-12', 'ESP',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Copa Ciudad de Madrid 2025'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Juvenil'),
  201, 63.50, 1.62);

CALL inscribir_atleta('Sofia', 'Lopez',      '2003-11-30', 'CHL',
  (SELECT id_competicion FROM competicion WHERE nombre_evento = 'Copa Ciudad de Madrid 2025'),
  (SELECT id_categoria   FROM categoria   WHERE nombre = 'Juvenil'),
  202, 58.50, 1.65);

-- -------------------------------------------------------
-- Verificaciones útiles (descomentar para probar)
-- -------------------------------------------------------

-- Historial completo de Carlos Gomez:
-- CALL historial_atleta((SELECT id_atleta FROM atleta WHERE nombre='Carlos' AND apellido='Gomez'));

-- Quién no está inscrito en el Torneo Apertura 2025:
-- CALL atletas_sin_inscripcion_en_evento(
--   (SELECT id_competicion FROM competicion WHERE nombre_evento='Torneo Apertura 2025'));

-- Vista general de todas las inscripciones:
-- SELECT a.nombre, a.apellido, c.nombre_evento, c.fecha,
--        cat.nombre AS categoria, i.peso_registro, i.estatura_registro
--   FROM inscripcion i
--   JOIN atleta      a   ON a.id_atleta      = i.id_atleta
--   JOIN competicion c   ON c.id_competicion = i.id_competicion
--   LEFT JOIN categoria cat ON cat.id_categoria = i.id_categoria
--   ORDER BY a.apellido, c.fecha;
