# Registro de acciones

Cada entrada: qué, dónde y cómo deshacerlo.

## 2026-11-01
- **Etiqueta de la barra lateral «COMANDOS» → «PROYECTOS».**
  Dónde: `Sources/CmdBoard/ContentView.swift:69`.
  Deshacer: volver a poner `"COMANDOS"` en esa línea y ejecutar `./build.sh`.
  Solo texto visible; no cambia el modelo de datos ni el JSON.
- **Regenerado `CmdBoard.app` con `./build.sh`.**
  Incluyó cambios previos sin commitear que no eran de esta sesión: botón «Ejecutar» (`ContentView.swift` ~342) y `Acciones.ejecutarEnTerminal` (`Store.swift` ~151).
  Deshacer: `git stash` o revertir esos hunks y ejecutar `./build.sh`.
- **Creados `CLAUDE.md` y `docs/RETOMAR.md`.**
  Deshacer: borrarlos (están sin commitear).
- **Añadido `MCP/CmdBoardMCP/` al repo** (`cmdboard_mcp_server.py`, `create_db.py`, `migrar_json_a_db.py`). Ignorados `.venv/`, `.idea/` y `__pycache__/` en `.gitignore`.
  Deshacer: `git revert` del commit y quitar esas 3 líneas de `.gitignore`.
- **Quitado `/Users/mossa` fijo de `MCP/CmdBoardMCP/cmdboard_mcp_server.py`** (ruta de `DB` y apertura de documentos): ahora `os.path.expanduser("~/...")`.
  Deshacer: `git checkout MCP/CmdBoardMCP/cmdboard_mcp_server.py`. No se ha ejecutado `build.sh`: no es código Swift.
- **README actualizado** a la implementación actual: sección PROYECTOS, botón Ejecutar, editar/borrar/reordenar, documentos Office/PDF, formato de exportación, `.bak`. El MCP se deja fuera del README a propósito (en desarrollo y pruebas).
  Deshacer: `git checkout README.md`. Sin cambios de código, no se ha ejecutado `build.sh`.
- **`MCP/` sacado del repo** (sigue en disco, ignorado en `.gitignore`) mientras está en desarrollo y pruebas. Además se eliminó del historial de GitHub con un push forzado (los commits `9d6c89b`, `0a127fe` y `70dbe72` se juntaron en uno). La rama de copia local `copia-antes-de-reescribir` se borró después; el historial anterior ya no está en ninguna rama.
  Deshacer: quitar `MCP/` de `.gitignore` y `git add MCP/CmdBoardMCP/*.py`.
