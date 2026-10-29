import Foundation

struct Comando: Identifiable, Codable, Hashable {
    var id = UUID()
    var etiqueta = ""
    var comando = ""
    var nota = ""
}

struct Enlace: Identifiable, Codable, Hashable {
    var id = UUID()
    var titulo = ""
    var rutaOUrl = ""

    enum CodingKeys: String, CodingKey {
        case id, titulo
        case rutaOUrl = "ruta_o_url"
    }
}

enum Navegador: String, Codable, CaseIterable, Identifiable {
    case safari, chrome, firefox

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .safari: "Safari"
        case .chrome: "Chrome"
        case .firefox: "Firefox"
        }
    }

    var bundleID: String {
        switch self {
        case .safari: "com.apple.Safari"
        case .chrome: "com.google.Chrome"
        case .firefox: "org.mozilla.firefox"
        }
    }
}

/// Pestaña guardada. Nunca lleva contraseñas: `usuarioLogin` es solo una referencia en texto plano
/// y `requiereLogin` un indicador visual. Si algún día se autocompleta, debe delegarse en el Llavero.
struct Pestana: Identifiable, Codable, Hashable {
    var id = UUID()
    var titulo = ""
    var url = ""
    /// Nombre del PNG en `miniaturas/` (vacío si aún no hay captura).
    var miniatura = ""
    var usuarioLogin = ""
    var requiereLogin = false

    enum CodingKeys: String, CodingKey {
        case id, titulo, url, miniatura
        case usuarioLogin = "usuario_login"
        case requiereLogin = "requiere_login"
    }
}

/// Conjunto de pestañas para abrir juntas. Es independiente de los proyectos de la sección Comandos.
struct GrupoNavegador: Identifiable, Codable, Hashable {
    var id = UUID()
    var nombre = "Grupo nuevo"
    var navegador: Navegador = .safari
    var pestanas: [Pestana] = []
}

/// Formato de exportación e importación: proyectos (Comandos) y grupos (Navegador).
struct Configuracion: Codable {
    var proyectos: [Proyecto]
    var navegadores: [GrupoNavegador]
}

struct Proyecto: Identifiable, Codable, Hashable {
    var id = UUID()
    var nombre = "Proyecto nuevo"
    var descripcion = ""
    var directorioTrabajo = ""
    var comandos: [Comando] = []
    var documentacion: [Enlace] = []

    enum CodingKeys: String, CodingKey {
        case id, nombre, descripcion, comandos, documentacion
        case directorioTrabajo = "directorio_trabajo"
    }
}

// En una extensión para conservar el init() por defecto. Las copias guardadas antes de
// existir `descripcion` no la traen, así que se lee como opcional.
extension Proyecto {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        nombre = try c.decode(String.self, forKey: .nombre)
        descripcion = try c.decodeIfPresent(String.self, forKey: .descripcion) ?? ""
        directorioTrabajo = try c.decode(String.self, forKey: .directorioTrabajo)
        comandos = try c.decode([Comando].self, forKey: .comandos)
        documentacion = try c.decode([Enlace].self, forKey: .documentacion)
    }
}
