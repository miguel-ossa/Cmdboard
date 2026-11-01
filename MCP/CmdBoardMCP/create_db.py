#!/usr/bin/env python3
"""Crea (o verifica) cmdboard.db con el esquema real de la app CmdBoard
(tomado de Models.swift / Store.swift / ContentView.swift / NavegadorView.swift).

Uso:
    python create_db.py                     # usa la ruta por defecto
    python create_db.py /ruta/a/cmdboard.db  # usa una ruta propia

Es idempotente: si las tablas ya existen, no hace nada (CREATE TABLE IF NOT EXISTS).
"""
import sqlite3
import pathlib
import sys

DEFAULT_PATH = "~/Library/Application Support/CmdBoard/cmdboard.db"
DB_PATH = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH).expanduser()

SCHEMA = """
PRAGMA foreign_keys = ON;

-- Proyecto (sección "Comandos" del sidebar). 'id' es el UUID real que usa
-- Swift (Identifiable/Codable), guardado como texto -- NO autoincremental,
-- para poder migrar proyectos.json sin regenerar identificadores.
-- No existe un campo "web": las URLs que se ven en el detalle del proyecto
-- salen de autodetectarlas dentro de 'descripcion' (ver DescripcionView).
CREATE TABLE IF NOT EXISTS proyectos (
    id                 TEXT PRIMARY KEY,
    nombre             TEXT NOT NULL DEFAULT 'Proyecto nuevo',
    descripcion        TEXT NOT NULL DEFAULT '',
    directorio_trabajo TEXT NOT NULL DEFAULT ''
);

-- Comandos de un proyecto (struct Comando: etiqueta, comando, nota).
-- 'orden' conserva la posición del array de Swift, usada al reordenar
-- arrastrando (Reordenar<Comando>).
CREATE TABLE IF NOT EXISTS comandos (
    id          TEXT PRIMARY KEY,
    proyecto_id TEXT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    etiqueta    TEXT NOT NULL DEFAULT '',
    comando     TEXT NOT NULL DEFAULT '',
    nota        TEXT NOT NULL DEFAULT '',
    orden       INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_comandos_proyecto ON comandos(proyecto_id);

-- Documentación de un proyecto (struct Enlace: titulo, ruta_o_url).
-- Un único campo para ruta de fichero O url web -- la app decide cómo abrirlo
-- mirando la extensión (Acciones.esDocumento), no hay columna de "tipo".
CREATE TABLE IF NOT EXISTS documentos (
    id          TEXT PRIMARY KEY,
    proyecto_id TEXT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
    titulo      TEXT NOT NULL DEFAULT '',
    ruta_o_url  TEXT NOT NULL DEFAULT '',
    orden       INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_documentos_proyecto ON documentos(proyecto_id);

-- Grupo del Navegador (struct GrupoNavegador). SIN relación con proyectos --
-- el modelo real no lleva proyecto_id, es una lista totalmente aparte.
-- 'navegador' guarda el rawValue del enum: 'safari' | 'chrome' | 'firefox'.
CREATE TABLE IF NOT EXISTS grupos_navegador (
    id        TEXT PRIMARY KEY,
    nombre    TEXT NOT NULL DEFAULT 'Grupo nuevo',
    navegador TEXT NOT NULL DEFAULT 'safari' CHECK (navegador IN ('safari', 'chrome', 'firefox'))
);

-- Pestaña dentro de un grupo (struct Pestana). 'id' debe conservarse tal cual
-- al migrar: Miniaturas.swift nombra el PNG como "<id>.png", así que si el id
-- cambiase se perdería la relación con la miniatura ya capturada en disco.
-- 'miniatura' es solo el nombre de fichero (vive en miniaturas/), nunca una
-- ruta completa. Nunca se guarda contraseña -- 'requiere_login' es un aviso
-- visual y 'usuario_login' una referencia de texto plano, nada más.
CREATE TABLE IF NOT EXISTS pestanas (
    id             TEXT PRIMARY KEY,
    grupo_id       TEXT NOT NULL REFERENCES grupos_navegador(id) ON DELETE CASCADE,
    titulo         TEXT NOT NULL DEFAULT '',
    url            TEXT NOT NULL DEFAULT '',
    miniatura      TEXT NOT NULL DEFAULT '',
    usuario_login  TEXT NOT NULL DEFAULT '',
    requiere_login INTEGER NOT NULL DEFAULT 0 CHECK (requiere_login IN (0, 1)),
    orden          INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_pestanas_grupo ON pestanas(grupo_id);
"""


def main() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB_PATH)
    con.executescript(SCHEMA)
    con.commit()

    tablas = con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
    ).fetchall()
    con.close()

    print(f"Base de datos lista en: {DB_PATH}")
    print("Tablas:", ", ".join(t[0] for t in tablas))


if __name__ == "__main__":
    main()
