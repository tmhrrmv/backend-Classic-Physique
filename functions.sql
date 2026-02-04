-- functions.sql
DELIMITER $$ 
-- Función: Calcular Edad exacta
CREATE FUNCTION fn_calcular_edad(fecha_nac DATE) RETURNS INT DETERMINISTIC
BEGIN
    DECLARE edad INT;
    SET edad = TIMESTAMPDIFF(YEAR, fecha_nac, CURDATE());
    -- Ajustar si aún no ha cumplido años este año
    IF DATE_FORMAT(CURDATE(), '%m%d') < DATE_FORMAT(fecha_nac, '%m%d') THEN
        SET edad = edad - 1;
    END IF;
    RETURN edad;
END$$ 
-- Función: Determinar categoría ideal basada en altura (Simplificada)
-- Nota: Esta es lógica de negocio, podría variar. Basado en datos insertados.
CREATE FUNCTION fn_determinar_categoria_altura(altura DECIMAL(5,2)) RETURNS VARCHAR(50) DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE nom_categoria VARCHAR(50);
    
    SELECT nombre INTO nom_categoria 
    FROM categoria 
    WHERE altura >= altura_min AND altura <= altura_max
    LIMIT 1;
    
    RETURN IFNULL(nom_categoria, 'Sin Categoría');
END$$ 
DELIMITER ;