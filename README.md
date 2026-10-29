<p align="center">
  <img src="logo_direct_design.png" alt="Logo de CmdBoard" width="160">
</p>

<h1 align="center">CmdBoard</h1>

<p align="center">
  Los comandos de terminal de cada proyecto, a un clic. App nativa para macOS, hecha con SwiftUI.
</p>

---

## Qué es

CmdBoard centraliza, **por proyecto**, los comandos que necesitas para arrancarlo (servidores de desarrollo, Claude Code con una configuración concreta, Omniroute, etc.), con un botón para copiarlos al portapapeles y enlaces a su documentación.

Es una app de **uso personal**: sin firma de código, sin notarización y sin App Store. Se compila y se ejecuta en local.

## Funciones

- **Panel lateral con dos secciones independientes**: **COMANDOS** (tus proyectos) y **NAVEGADOR** (grupos de pestañas). Cada una se crea, renombra y elimina por separado.
- **Descripción** libre por proyecto. Las direcciones web que escribas se convierten en enlaces pulsables.
- **Directorio de trabajo** opcional, con un botón para copiar el `cd` correspondiente.
- **Comandos** con etiqueta, texto exacto y nota opcional, cada uno con su botón **Copiar**.
- **Documentación**: rutas locales (PDF, ODT, etc.) o URLs. Se abren con la app por defecto del sistema.
- **Navegador** (sección propia del panel lateral, sin relación con los proyectos): cada grupo guarda un navegador y sus pestañas con título, URL, miniatura automática (regenerable), usuario opcional y un candado si requieren login. «Abrir pestañas» las lanza todas en Safari, Chrome o Firefox. **No se guardan contraseñas**: si algún día hay autocompletado, debe delegarse en el Llavero de macOS o en un gestor como 1Password o Bitwarden.
- **Aceptar / Descartar** cambios por proyecto. La app guarda sola en cada cambio; «Aceptar» fija el estado al que vuelve «Descartar».
- **Exportar e importar** toda la configuración en JSON, para copias de seguridad o para cambiar de Mac.

## Requisitos

- macOS 14 (Sonoma) o superior.
- Xcode, o al menos las Command Line Tools con Swift 5.9 o superior.

## Compilar y ejecutar

```bash
git clone <url-del-repositorio>
cd CmdBoard
./build.sh
open CmdBoard.app
```

`build.sh` compila en modo release con Swift Package Manager y monta `CmdBoard.app` (con su icono y su `Info.plist`) en la carpeta del proyecto. No hace falta abrir Xcode ni instalar dependencias.

> Si macOS bloquea la app al abrirla porque no está firmada: clic derecho sobre `CmdBoard.app` → **Abrir**.

## Dónde se guardan los datos

```
~/Library/Application Support/CmdBoard/proyectos.json
```

Es un JSON legible, que puedes copiar o editar a mano con la app cerrada. Cada proyecto tiene este aspecto:

```json
{
  "id": "…",
  "nombre": "Mi proyecto",
  "descripcion": "Notas y enlaces, por ejemplo https://ejemplo.com",
  "directorio_trabajo": "/Users/yo/Desarrollo/mi-proyecto",
  "comandos": [
    { "id": "…", "etiqueta": "Arrancar servidor dev", "comando": "npm run dev", "nota": "requiere Node 22" }
  ],
  "documentacion": [
    { "id": "…", "titulo": "Guía", "ruta_o_url": "https://ejemplo.com/guia" }
  ]
}
```

Los grupos del Navegador van aparte, en `navegador.json` (misma carpeta):

```json
{
  "id": "…",
  "nombre": "Cloudflare",
  "navegador": "safari",
  "pestanas": [
    { "id": "…", "titulo": "DNS", "url": "https://dash.cloudflare.com", "miniatura": "<id>.png",
      "usuario_login": "yo@ejemplo.com", "requiere_login": true }
  ]
}
```

Las miniaturas son PNG en `~/Library/Application Support/CmdBoard/miniaturas/` (no van en el JSON ni en la exportación; tras importar se regeneran con el botón de la pestaña). Se capturan con un navegador interno, así que en páginas con login verás la pantalla de login.

El menú **Archivo** tiene «Exportar configuración…» e «Importar configuración…». Importar **reemplaza** todo lo que haya, y pide confirmación antes.

## Estructura del proyecto

```
Package.swift             Definición del paquete (macOS 14)
build.sh                  Compila y genera CmdBoard.app
Resources/                Icono de la app y logo de la interfaz
Sources/CmdBoard/
  CmdBoardApp.swift       Punto de entrada y menú
  ContentView.swift       Panel lateral, detalle de proyecto y barras
  Descripcion.swift       Descripción con detección de enlaces
  Models.swift            Proyecto, Comando, Enlace, GrupoNavegador y Pestana (Codable)
  NavegadorView.swift     Grupo del Navegador: cuadrícula de pestañas
  Miniaturas.swift        Captura de miniaturas con WKWebView
  Store.swift             Persistencia, importar/exportar y acciones del sistema
  Tema.swift              Paleta y estilos (negro cálido, cobre y naranja)
```

## Pendiente (v2)

- Buscador rápido para filtrar proyectos y comandos.
- Comandos favoritos.
- Historial del último comando copiado por proyecto.
- Atajo de teclado global para abrir la app.

## Licencia

Por definir.
