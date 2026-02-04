-- sample_updates.sql

-- 1. Agregar puntuaciones a Lucas (ID Inscripción 3)
-- Esto disparará el trigger y actualizará su puntuación_total automáticamente
INSERT INTO puntuacion (id_inscripcion, id_juez, ranking_otorgado) VALUES (3, 1, 10);
INSERT INTO puntuacion (id_inscripcion, id_juez, ranking_otorgado) VALUES (3, 2, 9);

-- Verificar la actualización automática en la vista
SELECT * FROM vw_inscripciones_detalle;

-- 2. Actualizar una puntuación existente (Corrección de puntaje)
-- Si el Juez 1 se equivocó con Carlos (ID Inscripción 1) y quería darle 9 en lugar de 8
UPDATE puntuacion SET ranking_otorgado = 9 WHERE id_inscripcion = 1 AND id_juez = 1;

-- Verificar que la suma ahora es 18 (9+9)
SELECT * FROM vw_inscripciones_detalle WHERE id_inscripcion = 1;

-- 3. Establecer posiciones finales (Podium) basado en los puntos totales
-- Supongamos que queremos ordenar a los atletas de la competición 1
UPDATE inscripcion i
JOIN (
    SELECT id_inscripcion, ROW_NUMBER() OVER (ORDER BY puntuacion_total DESC) as posicion
    FROM inscripcion
    WHERE id_competicion = 1
) ranked ON i.id_inscripcion = ranked.id_inscripcion
SET i.posicion_final = ranked.posicion;

-- 4. Consultar el Ranking Final
SELECT * FROM vw_ranking_competicion;