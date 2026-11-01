#!/usr/bin/env python3
"""Migra proyectos.json y navegador.json (el formato real de CmdBoard,
ver Models.swift/Store.swift) a las tablas de cmdboard.db creadas por
create_db.py. Conserva los UUIDs originales -- imprescindible porque
Miniaturas.swift nombra cada PNG como "<id>.png".

Es seguro re-ejecutarlo: usa INSERT OR REPLACE, así que una segunda pasada
sobre los mismos JSON no duplica filas, solo las actualiza.

Uso:
    python migrar_json_a_db.py
    python migrar_json_a_db.py /ruta/a/cmdboard.db /ruta/a/proyectos.json /ruta/a/navegador.json
"""
import json
import pathlib
import sqlite3
import sys

BASE = pathlib.Path("~/Library/Application Support/CmdBoard").expanduser()


def main() -> None:
    db_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else BASE / "cmdboard.db"
    proyectos_path = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else BASE / "proyectos.json"
    navegador_path = pathlib.Path(sys.argv[3]) if len(sys.argv) > 3 else BASE / "navegador.json"

    con = sqlite3.connect(db_path)
    con.execute("PRAGMA foreign_keys = ON")

    n_proyectos = n_comandos = n_documentos = 0
    if proyectos_path.exists():
        proyectos = json.loads(proyectos_path.read_text(encoding="utf-8"))
        for p in proyectos:
            con.execute(
                "INSERT OR REPLACE INTO proyectos (id, nombre, descripcion, directorio_trabajo) "
                "VALUES (?, ?, ?, ?)",
                (p["id"], p.get("nombre", ""), p.get("descripcion", ""), p.get("directorio_trabajo", "")),
            )
            n_proyectos += 1
            for orden, c in enumerate(p.get("comandos", [])):
                con.execute(
                    "INSERT OR REPLACE INTO comandos (id, proyecto_id, etiqueta, comando, nota, orden) "
                    "VALUES (?, ?, ?, ?, ?, ?)",
                    (c["id"], p["id"], c.get("etiqueta", ""), c.get("comando", ""), c.get("nota", ""), orden),
                )
                n_comandos += 1
            for orden, d in enumerate(p.get("documentacion", [])):
                con.execute(
                    "INSERT OR REPLACE INTO documentos (id, proyecto_id, titulo, ruta_o_url, orden) "
                    "VALUES (?, ?, ?, ?, ?)",
                    (d["id"], p["id"], d.get("titulo", ""), d.get("ruta_o_url", ""), orden),
                )
                n_documentos += 1
    else:
        print(f"Aviso: no existe {proyectos_path}, salto proyectos/comandos/documentos")

    n_grupos = n_pestanas = 0
    if navegador_path.exists():
        grupos = json.loads(navegador_path.read_text(encoding="utf-8"))
        for g in grupos:
            con.execute(
                "INSERT OR REPLACE INTO grupos_navegador (id, nombre, navegador) VALUES (?, ?, ?)",
                (g["id"], g.get("nombre", ""), g.get("navegador", "safari")),
            )
            n_grupos += 1
            for orden, t in enumerate(g.get("pestanas", [])):
                con.execute(
                    "INSERT OR REPLACE INTO pestanas "
                    "(id, grupo_id, titulo, url, miniatura, usuario_login, requiere_login, orden) "
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    (
                        t["id"], g["id"], t.get("titulo", ""), t.get("url", ""),
                        t.get("miniatura", ""), t.get("usuario_login", ""),
                        1 if t.get("requiere_login") else 0, orden,
                    ),
                )
                n_pestanas += 1
    else:
        print(f"Aviso: no existe {navegador_path}, salto grupos/pestañas")

    con.commit()
    con.close()

    print(f"Migrado a {db_path}:")
    print(f"  proyectos: {n_proyectos}  comandos: {n_comandos}  documentos: {n_documentos}")
    print(f"  grupos_navegador: {n_grupos}  pestanas: {n_pestanas}")


if __name__ == "__main__":
    main()
