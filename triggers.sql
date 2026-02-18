-- ============================================================
-- ARCHIVO 2: triggers.sql
-- Orden de ejecución: 2° (después de create_tables.sql)
-- Base de datos: PostgreSQL
--
-- Se eliminó el trigger de "inscripción por defecto" porque
-- los atletas solo se inscriben en eventos reales con sus datos
-- físicos actuales. En su lugar se incluye validación automática
-- de que peso y estatura sean coherentes con la categoría.
-- ============================================================

DROP TRIGGER  IF EXISTS trg_validar_inscripcion_insert ON inscripcion;
DROP TRIGGER  IF EXISTS trg_validar_inscripcion_update ON inscripcion;
DROP FUNCTION IF EXISTS fn_validar_datos_inscripcion();

-- Función compartida por ambos triggers
CREATE OR REPLACE FUNCTION fn_validar_datos_inscripcion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_peso_max   NUMERIC;
  v_alt_min    NUMERIC;
  v_alt_max    NUMERIC;
BEGIN
  IF NEW.id_categoria IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT peso_maximo_permitido, altura_min, altura_max
    INTO v_peso_max, v_alt_min, v_alt_max
    FROM categoria
   WHERE id_categoria = NEW.id_categoria;

  IF NEW.peso_registro IS NOT NULL AND v_peso_max IS NOT NULL
     AND NEW.peso_registro > v_peso_max THEN
    RAISE EXCEPTION 'El peso del atleta (%) supera el máximo permitido (%) para la categoría',
      NEW.peso_registro, v_peso_max;
  END IF;

  IF NEW.estatura_registro IS NOT NULL AND v_alt_min IS NOT NULL
     AND NEW.estatura_registro < v_alt_min THEN
    RAISE EXCEPTION 'La estatura del atleta (%) es inferior al mínimo (%) de la categoría',
      NEW.estatura_registro, v_alt_min;
  END IF;

  IF NEW.estatura_registro IS NOT NULL AND v_alt_max IS NOT NULL
     AND NEW.estatura_registro > v_alt_max THEN
    RAISE EXCEPTION 'La estatura del atleta (%) supera el máximo (%) de la categoría',
      NEW.estatura_registro, v_alt_max;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger en INSERT
CREATE TRIGGER trg_validar_inscripcion_insert
BEFORE INSERT ON inscripcion
FOR EACH ROW EXECUTE FUNCTION fn_validar_datos_inscripcion();

-- Trigger en UPDATE (por si se corrige categoría o datos físicos)
CREATE TRIGGER trg_validar_inscripcion_update
BEFORE UPDATE ON inscripcion
FOR EACH ROW EXECUTE FUNCTION fn_validar_datos_inscripcion();
