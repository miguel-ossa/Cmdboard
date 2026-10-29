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
