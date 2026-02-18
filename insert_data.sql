-- ============================================================
-- ARCHIVO 4: insert_data.sql
-- Orden de ejecución: 4° (después de functions.sql)
-- Base de datos: MySQL
-- ============================================================

USE gestion_competiciones;

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
