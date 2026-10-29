import AppKit
import Foundation
import UniformTypeIdentifiers

final class Store: ObservableObject {
    @Published var proyectos: [Proyecto] = [] {
        didSet { guardar() }
    }

    @Published var ultimoGuardado: Date?

    /// Último estado aceptado (arranque o «Aceptar y salir»); a él vuelve «Descartar».
    private var aceptado: [Proyecto] = []
    var hayCambios: Bool { proyectos.contains { hayCambios($0.id) } }

    func hayCambios(_ id: UUID) -> Bool {
        proyectos.first { $0.id == id } != aceptado.first { $0.id == id }
    }

    private let archivo: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CmdBoard", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        archivo = base.appendingPathComponent("proyectos.json")
        if let datos = try? Data(contentsOf: archivo),
           let leidos = try? JSONDecoder().decode([Proyecto].self, from: datos) {
            proyectos = leidos
        }
        aceptado = proyectos
    }

    func aceptarCambios(_ id: UUID) {
        guard let p = proyectos.first(where: { $0.id == id }) else { return }
        if let i = aceptado.firstIndex(where: { $0.id == id }) { aceptado[i] = p } else { aceptado.append(p) }
        guardar()
    }

    /// Vuelve el proyecto a su último estado aceptado; si nunca se aceptó, desaparece.
    func descartarCambios(_ id: UUID) {
        guard let i = proyectos.firstIndex(where: { $0.id == id }) else { return }
        if let a = aceptado.first(where: { $0.id == id }) { proyectos[i] = a } else { proyectos.remove(at: i) }
    }

    /// Un borrado ya se confirma al hacerlo, así que no queda pendiente de aceptar.
    func eliminar(_ id: UUID) {
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

    func exportar() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "cmdboard-backup.json"
        guard panel.runModal() == .OK, let url = panel.url,
              let datos = try? codificador().encode(proyectos) else { return }
        try? datos.write(to: url, options: .atomic)
    }

    /// Reemplaza toda la configuración actual, previa confirmación.
    func importar() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let datos = try? Data(contentsOf: url),
              let leidos = try? JSONDecoder().decode([Proyecto].self, from: datos) else {
            let a = NSAlert()
            a.messageText = "No se pudo leer el archivo"
            a.informativeText = "No parece una exportación válida de CmdBoard."
            a.runModal()
            return
        }
        let a = NSAlert()
        a.messageText = "¿Reemplazar la configuración actual?"
        a.informativeText = "Se sustituirán tus \(proyectos.count) proyectos por los \(leidos.count) del archivo."
        a.addButton(withTitle: "Reemplazar")
        a.addButton(withTitle: "Cancelar")
        if a.runModal() == .alertFirstButtonReturn {
            proyectos = leidos
            aceptado = leidos
        }
    }
}

enum Acciones {
    static func copiar(_ texto: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(texto, forType: .string)
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
