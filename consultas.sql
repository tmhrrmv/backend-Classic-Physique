-- consultas.sql
-- Definición de Vistas para el Sistema de Gestión de Competiciones
-- Ejecutar después de crear las tablas (01_create_tables.sql)

SET NAMES utf8mb4;

-- ====================================================================
-- VISTAS
-- ====================================================================

-- Vista: Inscripciones detalladas con información de atleta y competición
-- Útil para ver el estado general de participación
DROP VIEW IF EXISTS vw_inscripciones_detalle;
CREATE OR REPLACE VIEW vw_inscripciones_detalle AS
SELECT 
    i.id_inscripcion,
    CONCAT(a.nombre, ' ', a.apellido) AS atleta,
    c.nombre_evento AS competicion,
    c.fecha AS fecha_competicion,
    cat.nombre AS categoria,
    i.numero_dorsal,
    i.peso_registro,
    i.estatura_registro,
    i.puntuacion_total,
    i.posicion_final,
    i.fecha_creacion
FROM inscripcion i
JOIN atleta a ON i.id_atleta = a.id_atleta
JOIN competicion c ON i.id_competicion = c.id_competicion
JOIN categoria cat ON i.id_categoria = cat.id_categoria;

-- Vista: Ranking por competición
-- Muestra el orden final basado en la posición
DROP VIEW IF EXISTS vw_ranking_competicion;
CREATE OR REPLACE VIEW vw_ranking_competicion AS
SELECT 
    c.id_competicion,
    c.nombre_evento,
    c.fecha,
    i.posicion_final,
    CONCAT(a.nombre, ' ', a.apellido) AS atleta,
    cat.nombre AS categoria,
    i.puntuacion_total,
    i.numero_dorsal
FROM competicion c
JOIN inscripcion i ON c.id_competicion = i.id_competicion
JOIN atleta a ON i.id_atleta = a.id_atleta
JOIN categoria cat ON i.id_categoria = cat.id_categoria
WHERE i.posicion_final IS NOT NULL
ORDER BY c.id_competicion, i.posicion_final;

-- Vista: Puntuaciones por juez
-- Estadísticas de las evaluaciones realizadas por cada juez
DROP VIEW IF EXISTS vw_puntuaciones_juez;
CREATE OR REPLACE VIEW vw_puntuaciones_juez AS
SELECT 
    j.id_juez,
    j.nombre AS juez,
    j.licencia,
    COUNT(p.id_puntuacion) AS total_evaluaciones,
    AVG(p.ranking_otorgado) AS ranking_promedio,
    MAX(p.ranking_otorgado) AS max_ranking,
    MIN(p.ranking_otorgado) AS min_ranking
FROM juez j
LEFT JOIN puntuacion p ON j.id_juez = p.id_juez
GROUP BY j.id_juez, j.nombre, j.licencia
ORDER BY total_evaluaciones DESC;