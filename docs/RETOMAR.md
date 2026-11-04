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
- **`MCP/` vuelto a subir a GitHub** (por petición de Miguel). Quitado de `.gitignore`; añadidos `cmdboard_mcp_server.py`, `create_db.py`, `migrar_json_a_db.py`. Otra vez sin `/Users/mossa` fijo en `cmdboard_mcp_server.py` (`os.path.expanduser`).
  Deshacer: `git revert` del commit (y `git push`), y volver a poner `MCP/` en `.gitignore`.

## 2026-11-02
- **Sincronización con SQLite en cada guardado.** Copiado `~/Downloads/SQLiteSync.swift` a `Sources/CmdBoard/SQLiteSync.swift`; `Store.guardar()` y `Store.guardarGrupos()` llaman a `SQLiteSync.compartido.sincronizar(...)` tras escribir el JSON (`Store.swift`). Reescribe `~/Library/Application Support/CmdBoard/cmdboard.db` entero en cada guardado. El JSON sigue siendo la fuente de verdad.
  Enlazado: el proyecto no es Xcode (no hay `project.pbxproj`), así que `-lsqlite3` va en `linkerSettings` de `Package.swift`.
  Deshacer: borrar `SQLiteSync.swift`, quitar las 2 líneas de `Store.swift`, revertir `Package.swift` (`git checkout Package.swift Sources/CmdBoard/Store.swift`) y ejecutar `./build.sh`.
- **Regenerado `CmdBoard.app` con `./build.sh`.** Sin otros cambios sin commitear ajenos. La app estaba abierta (PID 36477): hay que cerrarla y reabrirla para que use la versión nueva.
- **`SQLiteSync.swift` crea el esquema solo.** Sustituido el cuerpo de `Sources/CmdBoard/SQLiteSync.swift` por la versión de `~/Downloads`: `init()` crea la carpeta `Application Support/CmdBoard` y ejecuta los `CREATE TABLE IF NOT EXISTS` (idénticos a `create_db.py`) antes de sincronizar. Regenerado `CmdBoard.app` con `./build.sh`; la app seguía abierta, hay que reabrirla.
  Deshacer: volver a la versión anterior del fichero (no está commiteada: quitar el `esquema` y las 2 líneas nuevas de `init()`) y ejecutar `./build.sh`.
- **Prueba de `SQLiteSync` (creación del esquema desde cero).** Con un programa de prueba fuera del repo (scratchpad) que lee `proyectos.json` y `navegador.json` y llama a `SQLiteSync.sincronizar`. Incidente: la primera ejecución (con `HOME` falso, que macOS ignora) sobrescribió `cmdboard.db` real con datos de prueba. Corregido apartando ese `.db` y recreándolo desde cero con los JSON reales: 7 proyectos, 23 comandos, 8 docs, 3 grupos, 11 pestañas, coincide con los JSON. El `.db` anterior (con migración del 1-nov) no se conservó; el actual es el espejo de los JSON de hoy.
  Deshacer: no hace falta; el `.db` es derivado y se regenera en cada guardado. La copia con los datos de prueba está en el scratchpad y se puede borrar.

## 2026-11-04
- **Icono de tres rayas para reordenar PROYECTOS y NAVEGADOR.** `ContentView.swift`: cada fila de la barra lateral lleva el asa (`line.3.horizontal`) y acepta soltar con `Reordenar` (proyectos y grupos; nuevo `@State arrastrando`). `NavegadorView.swift`: las tarjetas de pestañas ya no se arrastran enteras, sino desde un asa en la esquina superior derecha. Sin cambios en el modelo de datos. Regenerado `CmdBoard.app` con `./build.sh` (app cerrada; sin cambios ajenos sin commitear).
  Deshacer: `git checkout Sources/CmdBoard/ContentView.swift Sources/CmdBoard/NavegadorView.swift` y `./build.sh`.
