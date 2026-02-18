-- ============================================================
-- ARCHIVO 1: create_tables.sql
-- Orden de ejecución: 1°
-- Base de datos: PostgreSQL
--
-- DISEÑO CLAVE:
--   - atleta guarda solo datos de IDENTIDAD (nombre, fecha nac.,
--     nacionalidad). Nunca cambian entre eventos.
--   - inscripcion guarda los datos FÍSICOS por cada evento:
--     peso, estatura y categoría pueden ser distintos en cada
--     competición porque el atleta evoluciona con el tiempo.
--   - Un atleta puede participar en N eventos con datos distintos.
--   - Un atleta NO puede inscribirse 2 veces en el mismo evento.
-- ============================================================

DROP TABLE IF EXISTS puntuacion   CASCADE;
DROP TABLE IF EXISTS inscripcion  CASCADE;
DROP TABLE IF EXISTS juez         CASCADE;
DROP TABLE IF EXISTS atleta       CASCADE;
DROP TABLE IF EXISTS competicion  CASCADE;
DROP TABLE IF EXISTS categoria    CASCADE;

-- categoria: rangos válidos por categoría de competición
CREATE TABLE categoria (
  id_categoria          SERIAL PRIMARY KEY,
  nombre                TEXT    UNIQUE NOT NULL,
  altura_min            NUMERIC,
  altura_max            NUMERIC,
  peso_maximo_permitido NUMERIC
);

-- competicion: cada evento es un registro independiente
CREATE TABLE competicion (
  id_competicion SERIAL PRIMARY KEY,
  nombre_evento  TEXT NOT NULL,
  fecha          DATE,
  lugar          TEXT,
  UNIQUE (nombre_evento, fecha)
);

-- atleta: datos de identidad fijos (no cambian entre eventos)
CREATE TABLE atleta (
  id_atleta        SERIAL PRIMARY KEY,
  nombre           TEXT NOT NULL,
  apellido         TEXT NOT NULL,
  fecha_nacimiento DATE NOT NULL,
  nacionalidad     TEXT,
  CONSTRAINT atleta_unique UNIQUE (nombre, apellido, fecha_nacimiento)
);

-- juez
CREATE TABLE juez (
  id_juez  SERIAL PRIMARY KEY,
  nombre   TEXT NOT NULL,
  licencia TEXT UNIQUE NOT NULL
);

-- inscripcion: una fila por (atleta x evento)
--   peso_registro, estatura_registro e id_categoria se registran
--   en el momento de cada evento: pueden cambiar entre competiciones.
--   UNIQUE (id_atleta, id_competicion) evita duplicados en el mismo
--   evento pero permite al mismo atleta aparecer en N eventos distintos.
CREATE TABLE inscripcion (
  id_inscripcion    SERIAL PRIMARY KEY,
  id_atleta         INT  NOT NULL REFERENCES atleta(id_atleta)           ON DELETE CASCADE,
  id_competicion    INT  NOT NULL REFERENCES competicion(id_competicion)  ON DELETE CASCADE,
  id_categoria      INT           REFERENCES categoria(id_categoria)      ON DELETE SET NULL,
  numero_dorsal     INT,
  peso_registro     NUMERIC,
  estatura_registro NUMERIC,
  fecha_inscripcion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (id_atleta, id_competicion)
);

-- puntuacion: nota de un juez sobre una inscripción concreta
CREATE TABLE puntuacion (
  id_puntuacion    SERIAL PRIMARY KEY,
  id_inscripcion   INT NOT NULL REFERENCES inscripcion(id_inscripcion) ON DELETE CASCADE,
  id_juez          INT NOT NULL REFERENCES juez(id_juez)               ON DELETE CASCADE,
  ranking_otorgado INT,
  UNIQUE (id_inscripcion, id_juez)
);

-- Índices para consultas frecuentes
CREATE INDEX idx_inscripcion_atleta      ON inscripcion(id_atleta);
CREATE INDEX idx_inscripcion_competicion ON inscripcion(id_competicion);
CREATE INDEX idx_puntuacion_inscripcion  ON puntuacion(id_inscripcion);
