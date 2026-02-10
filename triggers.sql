DELIMITER $$ 

-- =====================================================
-- 1. TRIGGERS DE VALIDACIÓN (BEFORE)
--    Se ejecutan antes de guardar. Detienen el proceso si hay error.
-- =====================================================

CREATE TRIGGER trg_puntuacion_validate_insert
BEFORE INSERT ON puntuacion
FOR EACH ROW
BEGIN
    -- Validar que los puntos no sean nulos
    IF NEW.ranking_otorgado IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: La puntuación no puede ser nula.';
    END IF;

    -- Validar que los puntos no sean negativos (Regla de Negocio)
    IF NEW.ranking_otorgado < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: La puntuación no puede ser negativa.';
    END IF;
    
    -- Validar límite máximo (ej. 100 puntos)
    IF NEW.ranking_otorgado > 100 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: La puntuación máxima permitida es 100.';
    END IF;
END$$ 

CREATE TRIGGER trg_puntuacion_validate_update
BEFORE UPDATE ON puntuacion
FOR EACH ROW
BEGIN
    -- Solo validar si el campo de puntos cambió
    IF NEW.ranking_otorgado <> OLD.ranking_otorgado THEN
        IF NEW.ranking_otorgado < 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Error: La puntuación no puede ser negativa.';
        END IF;
        
        IF NEW.ranking_otorgado > 100 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Error: La puntuación máxima permitida es 100.';
        END IF;
    END IF;
END$$ 


-- =====================================================
-- 2. TRIGGERS DE CÁLCULO Y ACTUALIZACIÓN (AFTER)
--    Se ejecutan después de guardar. Actualizan el total.
--    Si fallan aquí, MySQL hace ROLLBACK automático del INSERT.
-- =====================================================

CREATE TRIGGER trg_puntuacion_calc_insert
AFTER INSERT ON puntuacion
FOR EACH ROW
BEGIN
    -- Usamos cálculo diferencial (Sumar)
    UPDATE inscripcion 
    SET puntuacion_total = puntuacion_total + NEW.ranking_otorgado
    WHERE id_inscripcion = NEW.id_inscripcion;
END$$ 

CREATE TRIGGER trg_puntuacion_calc_update
AFTER UPDATE ON puntuacion
FOR EACH ROW
BEGIN
    -- Solo actualizar si el valor cambió
    IF NEW.ranking_otorgado <> OLD.ranking_otorgado THEN
        -- Resta lo que valía y suma lo nuevo
        UPDATE inscripcion 
        SET puntuacion_total = puntuacion_total - OLD.ranking_otorgado + NEW.ranking_otorgado
        WHERE id_inscripcion = NEW.id_inscripcion;
    END IF;
END$$ 

CREATE TRIGGER trg_puntuacion_calc_delete
AFTER DELETE ON puntuacion
FOR EACH ROW
BEGIN
    -- Resta los puntos que se borran
    UPDATE inscripcion 
    SET puntuacion_total = puntuacion_total - OLD.ranking_otorgado
    WHERE id_inscripcion = OLD.id_inscripcion;
END$$ 

DELIMITER ;
