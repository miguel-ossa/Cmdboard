import AppKit
import Foundation
import UniformTypeIdentifiers

final class Store: ObservableObject {
    @Published var proyectos: [Proyecto] = [] {
        didSet { guardar() }
    }

    @Published var grupos: [GrupoNavegador] = [] {
        didSet { guardarGrupos() }
    }

    @Published var ultimoGuardado: Date?

    /// Último estado aceptado (arranque o «Aceptar y salir»); a él vuelve «Descartar».
    private var aceptado: [Proyecto] = []
    private var aceptadoGrupos: [GrupoNavegador] = []
    var hayCambios: Bool {
        proyectos.contains { hayCambios($0.id) } || grupos.contains { hayCambios($0.id) }
    }

    /// Vale para proyectos y para grupos del Navegador: los ids no se repiten.
    func hayCambios(_ id: UUID) -> Bool {
        proyectos.first { $0.id == id } != aceptado.first { $0.id == id }
            || grupos.first { $0.id == id } != aceptadoGrupos.first { $0.id == id }
    }

    private let archivo: URL
    private let archivoGrupos: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CmdBoard", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        archivo = base.appendingPathComponent("proyectos.json")
        archivoGrupos = base.appendingPathComponent("navegador.json")
        // Copia de seguridad única del JSON anterior a la sección Navegador.
        let copia = base.appendingPathComponent("proyectos.json.bak")
        if FileManager.default.fileExists(atPath: archivo.path),
           !FileManager.default.fileExists(atPath: copia.path) {
            try? FileManager.default.copyItem(at: archivo, to: copia)
        }
        if let datos = try? Data(contentsOf: archivoGrupos),
           let leidos = try? JSONDecoder().decode([GrupoNavegador].self, from: datos) {
            grupos = leidos
        }
        aceptadoGrupos = grupos
        if let datos = try? Data(contentsOf: archivo),
           let leidos = try? JSONDecoder().decode([Proyecto].self, from: datos) {
            proyectos = leidos
        }
        aceptado = proyectos
    }

    func aceptarCambios(_ id: UUID) {
        if let p = proyectos.first(where: { $0.id == id }) {
            if let i = aceptado.firstIndex(where: { $0.id == id }) { aceptado[i] = p } else { aceptado.append(p) }
            guardar()
        } else if let g = grupos.first(where: { $0.id == id }) {
            if let i = aceptadoGrupos.firstIndex(where: { $0.id == id }) { aceptadoGrupos[i] = g } else { aceptadoGrupos.append(g) }
            guardarGrupos()
        }
    }

    /// Vuelve el proyecto a su último estado aceptado; si nunca se aceptó, desaparece.
    func descartarCambios(_ id: UUID) {
        if let i = grupos.firstIndex(where: { $0.id == id }) {
            if let a = aceptadoGrupos.first(where: { $0.id == id }) { grupos[i] = a } else { grupos.remove(at: i) }
            return
        }
        guard let i = proyectos.firstIndex(where: { $0.id == id }) else { return }
        if let a = aceptado.first(where: { $0.id == id }) { proyectos[i] = a } else { proyectos.remove(at: i) }
    }

    /// Un borrado ya se confirma al hacerlo, así que no queda pendiente de aceptar.
    func eliminar(_ id: UUID) {
        grupos.removeAll { $0.id == id }
        aceptadoGrupos.removeAll { $0.id == id }
        proyectos.removeAll { $0.id == id }
        aceptado.removeAll { $0.id == id }
    }

    private func codificador() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    private func guardar() {
        guard let datos = try? codificador().encode(proyectos) else { return }
        if (try? datos.write(to: archivo, options: .atomic)) != nil {
            ultimoGuardado = Date()
        }
    }

    private func guardarGrupos() {
        guard let datos = try? codificador().encode(grupos) else { return }
        if (try? datos.write(to: archivoGrupos, options: .atomic)) != nil {
            ultimoGuardado = Date()
        }
    }

    func exportar() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "cmdboard-backup.json"
        guard panel.runModal() == .OK, let url = panel.url,
              let datos = try? codificador().encode(Configuracion(proyectos: proyectos, navegadores: grupos)) else { return }
        try? datos.write(to: url, options: .atomic)
    }

    /// Reemplaza toda la configuración actual, previa confirmación.
    func importar() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        // Acepta el formato actual y el anterior (solo una lista de proyectos).
        let leido: Configuracion? = (try? Data(contentsOf: url)).flatMap { datos in
            if let c = try? JSONDecoder().decode(Configuracion.self, from: datos) { return c }
            return (try? JSONDecoder().decode([Proyecto].self, from: datos)).map { Configuracion(proyectos: $0, navegadores: []) }
        }
        guard let leido else {
            let a = NSAlert()
            a.messageText = "No se pudo leer el archivo"
            a.informativeText = "No parece una exportación válida de CmdBoard."
            a.runModal()
            return
        }
        let a = NSAlert()
        a.messageText = "¿Reemplazar la configuración actual?"
        a.informativeText = "Se sustituirán tus \(proyectos.count) proyectos y \(grupos.count) grupos del Navegador por los \(leido.proyectos.count) y \(leido.navegadores.count) del archivo."
        a.addButton(withTitle: "Reemplazar")
        a.addButton(withTitle: "Cancelar")
        if a.runModal() == .alertFirstButtonReturn {
            proyectos = leido.proyectos
            aceptado = leido.proyectos
            grupos = leido.navegadores
            aceptadoGrupos = leido.navegadores
        }
    }
}

enum Acciones {
    static func copiar(_ texto: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(texto, forType: .string)
    }

    /// Ejecuta el comando en una ventana nueva de Terminal (vía un .command temporal,
    /// que no necesita permisos de automatización). La ventana queda abierta al terminar.
    static func ejecutarEnTerminal(_ comando: String, directorio: String) {
        let dir = directorio.trimmingCharacters(in: .whitespacesAndNewlines)
        var guion = "#!/bin/zsh -l\nrm -f \"$0\"\n"
        if !dir.isEmpty {
            let ruta = (dir as NSString).expandingTildeInPath.replacingOccurrences(of: "'", with: "'\\''")
            guion += "cd '\(ruta)'\n"
        }
        guion += "\(comando)\nexec \"$SHELL\" -l\n"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cmdboard-\(UUID().uuidString).command")
        guard (try? guion.write(to: url, atomically: true, encoding: .utf8)) != nil else { return }
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        let terminal = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        NSWorkspace.shared.open([url], withApplicationAt: terminal, configuration: NSWorkspace.OpenConfiguration())
    }

    static func abrir(_ ruta: String) {
        let r = ruta.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !r.isEmpty else { return }
        if r.contains("://"), let url = URL(string: r) {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: (r as NSString).expandingTildeInPath))
        }
    }

    private static let extensionesDocumento: Set<String> = [
        "pdf",
        "doc", "docx", "docm", "dot", "dotx",
        "xls", "xlsx", "xlsm", "xlsb", "xlt", "xltx",
        "ppt", "pptx", "pptm", "pps", "ppsx",
        "odt", "ods", "odp", "odg", "odf", "ott", "ots", "otp",
    ]

    /// PDF o documento de LibreOffice / Microsoft Office, según la extensión.
    static func esDocumento(_ ruta: String) -> Bool {
        let r = ruta.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !r.isEmpty, !r.contains("://") else { return false }
        return extensionesDocumento.contains((r as NSString).pathExtension.lowercased())
    }

    /// Abre todas las URLs como pestañas nuevas en el navegador indicado.
    static func abrirPestanas(_ urls: [URL], en navegador: Navegador) {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: navegador.bundleID) else { return }
        NSWorkspace.shared.open(urls, withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
    }

    static func instalado(_ navegador: Navegador) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: navegador.bundleID) != nil
    }

    static func elegirCarpeta() -> String? {
        let p = NSOpenPanel()
        p.canChooseDirectories = true
        p.canChooseFiles = false
        return p.runModal() == .OK ? p.url?.path : nil
    }

    static func elegirArchivo() -> String? {
        let p = NSOpenPanel()
        return p.runModal() == .OK ? p.url?.path : nil
    }
}
