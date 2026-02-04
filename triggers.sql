-- triggers.sql
DELIMITER $$ 
-- Trigger para SUMAR puntos al INSERTAR una puntuación
CREATE TRIGGER trg_puntuacion_insert
AFTER INSERT ON puntuacion
FOR EACH ROW
BEGIN
    UPDATE inscripcion 
    SET puntuacion_total = (
        SELECT COALESCE(SUM(ranking_otorgado), 0) 
        FROM puntuacion 
        WHERE id_inscripcion = NEW.id_inscripcion
    )
    WHERE id_inscripcion = NEW.id_inscripcion;
END$$ 
-- Trigger para RECALCULAR puntos al ACTUALIZAR una puntuación
CREATE TRIGGER trg_puntuacion_update
AFTER UPDATE ON puntuacion
FOR EACH ROW
BEGIN
    UPDATE inscripcion 
    SET puntuacion_total = (
        SELECT COALESCE(SUM(ranking_otorgado), 0) 
        FROM puntuacion 
        WHERE id_inscripcion = NEW.id_inscripcion
    )
    WHERE id_inscripcion = NEW.id_inscripcion;
END$$ 
-- Trigger para RESTAR puntos al BORRAR una puntuación
CREATE TRIGGER trg_puntuacion_delete
AFTER DELETE ON puntuacion
FOR EACH ROW
BEGIN
    UPDATE inscripcion 
    SET puntuacion_total = (
        SELECT COALESCE(SUM(ranking_otorgado), 0) 
        FROM puntuacion 
        WHERE id_inscripcion = OLD.id_inscripcion
    )
    WHERE id_inscripcion = OLD.id_inscripcion;
END$$ 
DELIMITER ;