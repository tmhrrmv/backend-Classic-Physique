-- ====================================================================
-- SCRIPT DE FUNCIONES (functions.sql)
-- ====================================================================

USE competencia_db;

DELIMITER $$ 
-- =====================================================
-- 1. FUNCIÓN: Calcular Edad Exacta
--    CORRECCIÓN: TIMESTAMPDIFF ya calcula años completos.
--    La lógica manual anterior causaba que se restara un año
--    de más cuando aún no había pasado el cumpleaños.
-- =====================================================
CREATE FUNCTION fn_calcular_edad(fecha_nac DATE) RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    -- TIMESTAMPDIFF(YEAR, ...) calcula automáticamente cuántos años
    -- completos han pasado entre dos fechas, manejando bisiestos y días.
    RETURN TIMESTAMPDIFF(YEAR, fecha_nac, CURDATE());
END$$ 
-- =====================================================
-- 2. FUNCIÓN: Determinar categoría ideal basada en altura
--    Nota: Usa los rangos definidos en la tabla 'categoria'.
-- =====================================================
CREATE FUNCTION fn_determinar_categoria_altura(p_altura DECIMAL(5,2)) RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE nom_categoria VARCHAR(50);
    
    -- Buscamos la categoría donde la altura ingresada (parámetro)
    -- esté entre la altura mínima y máxima de la tabla.
    -- Se usa 'p_altura' para evitar ambigüedades con nombres de columnas.
    SELECT nombre INTO nom_categoria 
    FROM categoria 
    WHERE p_altura >= altura_min AND p_altura <= altura_max
    LIMIT 1;
    
    RETURN IFNULL(nom_categoria, 'Sin Categoría');
END$$ 
DELIMITER ;
