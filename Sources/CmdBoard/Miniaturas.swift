import AppKit
import SwiftUI
import WebKit

/// Capturas de pantalla de las pestañas guardadas. Los PNG viven en
/// `~/Library/Application Support/CmdBoard/miniaturas/<id>.png`; el JSON solo guarda el nombre.
/// Se renderizan con un WKWebView propio, así que las páginas con login muestran la pantalla de login.
@MainActor
final class Miniaturas: ObservableObject {
    static let compartido = Miniaturas()

    /// Cambia al regenerar una captura, para que la cuadrícula la vuelva a leer.
    @Published private(set) var version = 0
    @Published private(set) var capturando: Set<UUID> = []

    private let carpeta: URL = {
        let d = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CmdBoard/miniaturas", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    func imagen(_ nombre: String) -> NSImage? {
        nombre.isEmpty ? nil : NSImage(contentsOf: carpeta.appendingPathComponent(nombre))
    }

    /// Normaliza lo escrito por el usuario: añade https:// si falta el esquema.
    static func url(_ texto: String) -> URL? {
        let t = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        let u = URL(string: t.contains("://") ? t : "https://" + t)
        return u?.host == nil ? nil : u
    }

    /// Captura la página y devuelve el nombre del PNG y el título de la página, o nil si falla.
    func capturar(id: UUID, url texto: String) async -> (archivo: String, titulo: String)? {
        guard let url = Self.url(texto), !capturando.contains(id) else { return nil }
        capturando.insert(id)
        defer { capturando.remove(id) }
        let captor = Captor()
        guard let (imagen, titulo) = await captor.capturar(url) else { return nil }
        let nombre = "\(id.uuidString).png"
        guard let tiff = imagen.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]),
              (try? png.write(to: carpeta.appendingPathComponent(nombre), options: .atomic)) != nil else { return nil }
        version += 1
        return (nombre, titulo)
    }
}

@MainActor
private final class Captor: NSObject, WKNavigationDelegate {
    private let web: WKWebView
    private let ventana: NSWindow
    private var continuacion: CheckedContinuation<(NSImage, String)?, Never>?

    override init() {
        let marco = NSRect(x: 0, y: 0, width: 1280, height: 800)
        web = WKWebView(frame: marco, configuration: WKWebViewConfiguration())
        // Ventana sin mostrar: sin ella WebKit no siempre llega a pintar.
        ventana = NSWindow(contentRect: marco, styleMask: [.borderless], backing: .buffered, defer: true)
        ventana.contentView = web
        super.init()
        web.navigationDelegate = self
    }

    func capturar(_ url: URL) async -> (NSImage, String)? {
        await withCheckedContinuation { c in
            continuacion = c
            web.load(URLRequest(url: url, timeoutInterval: 20))
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(25))
                self?.terminar(nil)
            }
        }
    }

    private func terminar(_ r: (NSImage, String)?) {
        continuacion?.resume(returning: r)
        continuacion = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))   // deja asentarse el contenido dinámico
            let ajustes = WKSnapshotConfiguration()
            ajustes.snapshotWidth = 640
            let imagen = try? await webView.takeSnapshot(configuration: ajustes)
            terminar(imagen.map { ($0, webView.title ?? "") })
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { terminar(nil) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { terminar(nil) }
}
