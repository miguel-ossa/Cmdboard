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
