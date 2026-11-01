from mcp.server.mcpserver import MCPServer
import os, pathlib, sqlite3, subprocess, tempfile, uuid

mcp = MCPServer("cmdboard")
DB = os.path.expanduser("~/Library/Application Support/CmdBoard/cmdboard.db")

# Bundle IDs reales, los mismos que usa Navegador.swift/Models.swift en la app.
BUNDLE_ID = {
    "safari": "com.apple.Safari",
    "chrome": "com.google.Chrome",
    "firefox": "org.mozilla.firefox",
}


def _conn():
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    return con


def _nuevo_id() -> str:
    """UUID en el mismo formato que Swift (UUID().uuidString): mayúsculas con guiones."""
    return str(uuid.uuid4()).upper()


def _siguiente_orden(con, tabla: str, columna_padre: str, id_padre: str) -> int:
    row = con.execute(
        f"SELECT COALESCE(MAX(orden), -1) + 1 AS n FROM {tabla} WHERE {columna_padre} = ?",
        (id_padre,),
    ).fetchone()
    return row["n"]


# --- Proyectos ---

@mcp.tool()
def get_proyecto(nombre: str) -> dict | None:
    """Devuelve id, descripción y directorio de trabajo de un proyecto por nombre."""
    row = _conn().execute(
        "SELECT id, nombre, descripcion, directorio_trabajo FROM proyectos WHERE nombre = ?",
        (nombre,),
    ).fetchone()
    return dict(row) if row else None


# --- Comandos ---

@mcp.tool()
def list_commands(proyecto: str) -> list[dict]:
    """Lista los comandos guardados de un proyecto (por nombre), ordenados."""
    rows = _conn().execute(
        "SELECT comandos.id, comandos.etiqueta, comandos.comando, comandos.nota "
        "FROM comandos JOIN proyectos ON proyectos.id = comandos.proyecto_id "
        "WHERE proyectos.nombre = ? ORDER BY comandos.orden",
        (proyecto,),
    ).fetchall()
    return [dict(r) for r in rows]


@mcp.tool()
def add_command(proyecto: str, etiqueta: str, comando: str, nota: str = "") -> str:
    """Añade un comando (puede ser multilínea) a un proyecto, por nombre de proyecto."""
    con = _conn()
    p = con.execute("SELECT id FROM proyectos WHERE nombre = ?", (proyecto,)).fetchone()
    if p is None:
        return f"No existe el proyecto '{proyecto}'"
    orden = _siguiente_orden(con, "comandos", "proyecto_id", p["id"])
    con.execute(
        "INSERT INTO comandos (id, proyecto_id, etiqueta, comando, nota, orden) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (_nuevo_id(), p["id"], etiqueta, comando, nota, orden),
    )
    con.commit()
    return f"Comando '{etiqueta}' añadido a {proyecto}"


@mcp.tool()
def update_command(id: str, etiqueta: str | None = None, comando: str | None = None, nota: str | None = None) -> str:
    """Edita un comando existente por id. Solo cambia los campos que se pasen."""
    con = _conn()
    actual = con.execute("SELECT etiqueta, comando, nota FROM comandos WHERE id=?", (id,)).fetchone()
    if actual is None:
        return f"No existe el comando {id}"
    con.execute(
        "UPDATE comandos SET etiqueta=?, comando=?, nota=? WHERE id=?",
        (
            etiqueta if etiqueta is not None else actual["etiqueta"],
            comando if comando is not None else actual["comando"],
            nota if nota is not None else actual["nota"],
            id,
        ),
    )
    con.commit()
    return f"Comando {id} actualizado"


@mcp.tool()
def delete_command(id: str) -> str:
    """Borra un comando guardado por id."""
    con = _conn()
    con.execute("DELETE FROM comandos WHERE id=?", (id,))
    con.commit()
    return f"Comando {id} borrado"


@mcp.tool()
def run_command(id: str, confirmar: bool = False) -> dict:
    """Ejecuta un comando YA GUARDADO, identificado por id — nunca texto libre.
    Sin confirmar=True, solo devuelve el texto para que lo valides antes de lanzarlo."""
    con = _conn()
    row = con.execute(
        "SELECT comandos.comando, proyectos.directorio_trabajo FROM comandos "
        "JOIN proyectos ON proyectos.id = comandos.proyecto_id WHERE comandos.id=?",
        (id,),
    ).fetchone()
    if row is None:
        return {"error": f"No existe el comando {id}"}
    if not confirmar:
        return {"pendiente_confirmar": row["comando"], "directorio_trabajo": row["directorio_trabajo"]}
    resultado = subprocess.run(
        row["comando"], shell=True, cwd=row["directorio_trabajo"] or None,
        capture_output=True, text=True, timeout=120,
    )
    return {"stdout": resultado.stdout, "stderr": resultado.stderr, "codigo": resultado.returncode}


def _ejecutar_en_terminal(comando: str, directorio: str) -> str:
    """Replica Acciones.ejecutarEnTerminal de la app: un .command temporal que se
    autodestruye (rm -f "$0"), hace cd al directorio y lanza el comando en una
    ventana nueva de Terminal, con la shell abierta al terminar (exec "$SHELL" -l)."""
    guion = '#!/bin/zsh -l\nrm -f "$0"\n'
    if directorio:
        ruta = directorio.replace("'", "'\\''")
        guion += f"cd '{ruta}'\n"
    guion += f'{comando}\nexec "$SHELL" -l\n'
    script = pathlib.Path(tempfile.gettempdir()) / f"cmdboard-{_nuevo_id()}.command"
    script.write_text(guion)
    script.chmod(0o700)
    subprocess.run(["open", "-a", "/System/Applications/Utilities/Terminal.app", str(script)], check=True)
    return str(script)


@mcp.tool()
def run_command_interactive(id: str) -> str:
    """Para comandos interactivos (REPLs como 'claude', Omniroute) que necesitan una
    terminal real con stdin -- run_command normal falla en estos porque captura la
    salida sin dar un terminal. Abre una ventana nueva de Terminal y lanza el comando
    ahí, igual que el botón 'Ejecutar' de la app. No captura salida ni espera a que
    termine: usa run_command para comandos que sí dan una salida que leer."""
    con = _conn()
    row = con.execute(
        "SELECT comando, directorio_trabajo FROM comandos "
        "JOIN proyectos ON proyectos.id = comandos.proyecto_id WHERE comandos.id=?",
        (id,),
    ).fetchone()
    if row is None:
        return f"No existe el comando {id}"
    ruta = _ejecutar_en_terminal(row["comando"], row["directorio_trabajo"] or "")
    return f"Abierto en una ventana nueva de Terminal ({ruta})"


# --- Documentación ---

@mcp.tool()
def list_docs(proyecto: str) -> list[dict]:
    """Lista los documentos guardados de un proyecto (por nombre), con su id y ruta o url."""
    rows = _conn().execute(
        "SELECT documentos.id, documentos.titulo, documentos.ruta_o_url "
        "FROM documentos JOIN proyectos ON proyectos.id = documentos.proyecto_id "
        "WHERE proyectos.nombre = ? ORDER BY documentos.orden",
        (proyecto,),
    ).fetchall()
    return [dict(r) for r in rows]


@mcp.tool()
def add_doc(proyecto: str, titulo: str, ruta_o_url: str) -> str:
    """Añade un documento a un proyecto. ruta_o_url puede ser una ruta de fichero o una URL web."""
    con = _conn()
    p = con.execute("SELECT id FROM proyectos WHERE nombre = ?", (proyecto,)).fetchone()
    if p is None:
        return f"No existe el proyecto '{proyecto}'"
    orden = _siguiente_orden(con, "documentos", "proyecto_id", p["id"])
    con.execute(
        "INSERT INTO documentos (id, proyecto_id, titulo, ruta_o_url, orden) VALUES (?, ?, ?, ?, ?)",
        (_nuevo_id(), p["id"], titulo, ruta_o_url, orden),
    )
    con.commit()
    return f"Documento '{titulo}' añadido a {proyecto}"


@mcp.tool()
def open_doc(id: str) -> str:
    """Abre un documento: como URL si ruta_o_url es una, si no como fichero local (igual que Acciones.abrir)."""
    con = _conn()
    row = con.execute("SELECT ruta_o_url FROM documentos WHERE id=?", (id,)).fetchone()
    if row is None:
        return f"No existe el documento {id}"
    destino = row["ruta_o_url"]
    if "://" in destino:
        subprocess.run(["open", destino], check=True)
    else:
        subprocess.run(["open", os.path.expanduser(destino)], check=True)
    return f"Abriendo {destino}"


@mcp.tool()
def delete_doc(id: str) -> str:
    """Borra un documento guardado por id (solo el registro, no el fichero)."""
    con = _conn()
    con.execute("DELETE FROM documentos WHERE id=?", (id,))
    con.commit()
    return f"Documento {id} borrado"


# --- Navegador: grupos y pestañas (sin relación con proyectos) ---

@mcp.tool()
def list_grupos_navegador() -> list[dict]:
    """Lista los grupos de Navegador, con su navegador por defecto."""
    rows = _conn().execute("SELECT id, nombre, navegador FROM grupos_navegador").fetchall()
    return [dict(r) for r in rows]


@mcp.tool()
def list_pestanas(grupo: str) -> list[dict]:
    """Lista las pestañas de un grupo de Navegador, por nombre de grupo."""
    rows = _conn().execute(
        "SELECT pestanas.id, pestanas.titulo, pestanas.url, pestanas.requiere_login "
        "FROM pestanas JOIN grupos_navegador ON grupos_navegador.id = pestanas.grupo_id "
        "WHERE grupos_navegador.nombre = ? ORDER BY pestanas.orden",
        (grupo,),
    ).fetchall()
    return [dict(r) for r in rows]


@mcp.tool()
def add_pestana(grupo: str, titulo: str, url: str, usuario_login: str = "", requiere_login: bool = False) -> str:
    """Añade una pestaña a un grupo de Navegador existente, por nombre de grupo."""
    con = _conn()
    g = con.execute("SELECT id FROM grupos_navegador WHERE nombre = ?", (grupo,)).fetchone()
    if g is None:
        return f"No existe el grupo '{grupo}'"
    orden = _siguiente_orden(con, "pestanas", "grupo_id", g["id"])
    con.execute(
        "INSERT INTO pestanas (id, grupo_id, titulo, url, miniatura, usuario_login, requiere_login, orden) "
        "VALUES (?, ?, ?, ?, '', ?, ?, ?)",
        (_nuevo_id(), g["id"], titulo, url, usuario_login, 1 if requiere_login else 0, orden),
    )
    con.commit()
    return f"Pestaña '{titulo}' añadida a {grupo}"


@mcp.tool()
def delete_pestana(id: str) -> str:
    """Borra una pestaña guardada por id."""
    con = _conn()
    con.execute("DELETE FROM pestanas WHERE id=?", (id,))
    con.commit()
    return f"Pestaña {id} borrada"


@mcp.tool()
def abrir_pestana(id: str) -> str:
    """Abre una pestaña en el navegador por defecto de su grupo (bundle ID, como la app)."""
    con = _conn()
    row = con.execute(
        "SELECT pestanas.url, grupos_navegador.navegador FROM pestanas "
        "JOIN grupos_navegador ON grupos_navegador.id = pestanas.grupo_id WHERE pestanas.id=?",
        (id,),
    ).fetchone()
    if row is None:
        return f"No existe la pestaña {id}"
    bundle_id = BUNDLE_ID.get(row["navegador"], BUNDLE_ID["safari"])
    subprocess.run(["open", "-b", bundle_id, row["url"]], check=True)
    return f"Abriendo {row['url']} en {row['navegador']}"


@mcp.tool()
def abrir_pestanas_grupo(grupo: str) -> str:
    """Abre TODAS las pestañas de un grupo a la vez, en el navegador del grupo — como el botón 'Abrir pestañas'."""
    con = _conn()
    g = con.execute("SELECT id, navegador FROM grupos_navegador WHERE nombre = ?", (grupo,)).fetchone()
    if g is None:
        return f"No existe el grupo '{grupo}'"
    urls = [r["url"] for r in con.execute(
        "SELECT url FROM pestanas WHERE grupo_id = ? ORDER BY orden", (g["id"],)
    ).fetchall()]
    if not urls:
        return f"'{grupo}' no tiene pestañas guardadas"
    bundle_id = BUNDLE_ID.get(g["navegador"], BUNDLE_ID["safari"])
    subprocess.run(["open", "-b", bundle_id, *urls], check=True)
    return f"Abriendo {len(urls)} pestañas de '{grupo}' en {g['navegador']}"


if __name__ == "__main__":
    mcp.run(transport="stdio")
