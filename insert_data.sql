-- insert_data.sql

-- 1. Categorías
INSERT INTO categoria (nombre, altura_min, altura_max, peso_maximo_permitido) VALUES
('Cadete', 1.40, 1.59, 60.00),
('Juvenil', 1.60, 1.75, 75.00),
('Senior', 1.76, 2.20, 120.00);

-- 2. Competiciones (Fechas futuras)
INSERT INTO competicion (nombre_evento, fecha, lugar) VALUES
('Torneo Apertura Regional', DATE_ADD(CURDATE(), INTERVAL 15 DAY), 'Estadio Nacional'),
('Copa Ciudad de Madrid', DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Centro Deportivo Municipal');

-- 3. Atletas
INSERT INTO atleta (nombre, apellido, fecha_nacimiento, nacionalidad) VALUES
('Carlos', 'Gomez', '2005-04-12', 'ESP'),
('Maria', 'Rodriguez', '2004-08-22', 'MEX'),
('Lucas', 'Fernandez', '2002-01-15', 'ARG'),
('Sofia', 'Lopez', '2003-11-30', 'CHL');

-- 4. Jueces
INSERT INTO juez (nombre, licencia) VALUES
('Roberto Diaz', 'JUE-001'),
('Ana Martinez', 'JUE-002');

-- 5. Inscripciones
-- Carlos inscrito en Torneo Apertura (Cadete)
INSERT INTO inscripcion (id_atleta, id_competicion, id_categoria, numero_dorsal, peso_registro, estatura_registro) 
VALUES (1, 1, 1, 101, 55.50, 1.55);

-- Maria inscrita en Torneo Apertura (Juvenil)
INSERT INTO inscripcion (id_atleta, id_competicion, id_categoria, numero_dorsal, peso_registro, estatura_registro) 
VALUES (2, 1, 2, 102, 62.00, 1.68);

-- Lucas inscrito en Torneo Apertura (Senior)
INSERT INTO inscripcion (id_atleta, id_competicion, id_categoria, numero_dorsal, peso_registro, estatura_registro) 
VALUES (3, 1, 3, 103, 85.00, 1.80);

-- 6. Puntuaciones (Rankings otorgados por jueces)
-- Para Carlos (Inscripción 1)
INSERT INTO puntuacion (id_inscripcion, id_juez, ranking_otorgado) VALUES (1, 1, 8);
INSERT INTO puntuacion (id_inscripcion, id_juez, ranking_otorgado) VALUES (1, 2, 9);

-- Para Maria (Inscripción 2)
INSERT INTO puntuacion (id_inscripcion, id_juez, ranking_otorgado) VALUES (2, 1, 7);
INSERT INTO puntuacion (id_inscripcion, id_juez, ranking_otorgado) VALUES (2, 2, 8);

-- Para Lucas (Inscripción 3) - Sin puntuaciones aún para probar updates posteriores