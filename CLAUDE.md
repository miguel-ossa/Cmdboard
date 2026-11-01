# CmdBoard

## Build
- Tras cualquier cambio en el código de la app, ejecutar `./build.sh` (no basta `swift build`) para regenerar `CmdBoard.app`, y avisar de si la app estaba abierta.
- `build.sh` compila todo lo que haya en el directorio, incluidos cambios sin commitear que no sean míos: decirlo si los hay.

## Datos
- Se guardan en JSON en `~/Library/Application Support/CmdBoard/` (`proyectos.json`, `navegador.json`, `miniaturas/`). Modelos en `Sources/CmdBoard/Models.swift`.
- No cambiar el modelo de datos ni los nombres de claves del JSON sin pedirlo antes.

## Registro
- Anotar cada cambio (qué, dónde y cómo deshacerlo) en `docs/RETOMAR.md`.
