import Foundation
import SQLite3

/// Mantiene cmdboard.db sincronizado con el estado en memoria de Store, para que el
/// servidor MCP lea siempre datos frescos sin depender de ningún script de migración.
///
/// Estrategia: resincronización completa en cada guardado (borra todo, reinserta desde
/// los arrays actuales), en vez de UPDATE selectivo -- así nunca hay dos estados que
/// reconciliar. guardar()/guardarGrupos() ya reescriben el JSON entero en cada edición
/// (incluida cada pulsación de tecla), así que esto no añade un patrón de coste nuevo,
/// solo lo espeja en SQLite.
///
/// Requiere enlazar libsqlite3.tbd: Target > Build Phases > Link Binary With Libraries > +.
final class SQLiteSync {
    static let compartido = SQLiteSync()
    private let db: OpaquePointer?
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    /// Mismas CREATE TABLE IF NOT EXISTS que create_db.py -- idempotentes, así que
    /// ejecutarlas en cada arranque no hace nada si el esquema ya existe. Esto es lo
    /// que evita el fallo silencioso: una instalación nueva, o una donde se haya
    /// borrado cmdboard.db por error, se repara sola en el primer guardado.
    private static let esquema = """
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS proyectos (
        id      TEXT PRIMARY KEY,
        nombre  TEXT NOT NULL DEFAULT 'Proyecto nuevo',
        descripcion TEXT NOT NULL DEFAULT '',
        directorio_trabajo TEXT NOT NULL DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS comandos (
        id          TEXT PRIMARY KEY,
        proyecto_id TEXT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
        etiqueta    TEXT NOT NULL DEFAULT '',
        comando     TEXT NOT NULL DEFAULT '',
        nota        TEXT NOT NULL DEFAULT '',
        orden       INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX IF NOT EXISTS idx_comandos_proyecto ON comandos(proyecto_id);

    CREATE TABLE IF NOT EXISTS documentos (
        id          TEXT PRIMARY KEY,
        proyecto_id TEXT NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
        titulo      TEXT NOT NULL DEFAULT '',
        ruta_o_url  TEXT NOT NULL DEFAULT '',
        orden       INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX IF NOT EXISTS idx_documentos_proyecto ON documentos(proyecto_id);

    CREATE TABLE IF NOT EXISTS grupos_navegador (
        id        TEXT PRIMARY KEY,
        nombre    TEXT NOT NULL DEFAULT 'Grupo nuevo',
        navegador TEXT NOT NULL DEFAULT 'safari' CHECK (navegador IN ('safari', 'chrome', 'firefox'))
    );

    CREATE TABLE IF NOT EXISTS pestanas (
        id             TEXT PRIMARY KEY,
        grupo_id       TEXT NOT NULL REFERENCES grupos_navegador(id) ON DELETE CASCADE,
        titulo         TEXT NOT NULL DEFAULT '',
        url            TEXT NOT NULL DEFAULT '',
        miniatura      TEXT NOT NULL DEFAULT '',
        usuario_login  TEXT NOT NULL DEFAULT '',
        requiere_login INTEGER NOT NULL DEFAULT 0 CHECK (requiere_login IN (0, 1)),
        orden          INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX IF NOT EXISTS idx_pestanas_grupo ON pestanas(grupo_id);
    """

    private init() {
        let carpeta = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CmdBoard", isDirectory: true)
        try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
        let ruta = carpeta.appendingPathComponent("cmdboard.db").path
        var conexion: OpaquePointer?
        if sqlite3_open(ruta, &conexion) == SQLITE_OK {
            db = conexion
            sqlite3_exec(db, Self.esquema, nil, nil, nil)
        } else {
            db = nil
        }
    }

    func sincronizar(proyectos: [Proyecto], grupos: [GrupoNavegador]) {
        guard let db else { return }
        sqlite3_exec(db, "BEGIN TRANSACTION", nil, nil, nil)

        for tabla in ["comandos", "documentos", "pestanas", "proyectos", "grupos_navegador"] {
            sqlite3_exec(db, "DELETE FROM \(tabla)", nil, nil, nil)
        }

        for p in proyectos {
            insertar(
                "INSERT INTO proyectos (id, nombre, descripcion, directorio_trabajo) VALUES (?,?,?,?)",
                [p.id.uuidString, p.nombre, p.descripcion, p.directorioTrabajo]
            )
            for (i, c) in p.comandos.enumerated() {
                insertar(
                    "INSERT INTO comandos (id, proyecto_id, etiqueta, comando, nota, orden) VALUES (?,?,?,?,?,?)",
                    [c.id.uuidString, p.id.uuidString, c.etiqueta, c.comando, c.nota, i]
                )
            }
            for (i, d) in p.documentacion.enumerated() {
                insertar(
                    "INSERT INTO documentos (id, proyecto_id, titulo, ruta_o_url, orden) VALUES (?,?,?,?,?)",
                    [d.id.uuidString, p.id.uuidString, d.titulo, d.rutaOUrl, i]
                )
            }
        }
        for g in grupos {
            insertar(
                "INSERT INTO grupos_navegador (id, nombre, navegador) VALUES (?,?,?)",
                [g.id.uuidString, g.nombre, g.navegador.rawValue]
            )
            for (i, t) in g.pestanas.enumerated() {
                insertar(
                    "INSERT INTO pestanas (id, grupo_id, titulo, url, miniatura, usuario_login, requiere_login, orden) VALUES (?,?,?,?,?,?,?,?)",
                    [t.id.uuidString, g.id.uuidString, t.titulo, t.url, t.miniatura, t.usuarioLogin, t.requiereLogin ? 1 : 0, i]
                )
            }
        }

        sqlite3_exec(db, "COMMIT", nil, nil, nil)
    }

    /// `valores` solo lleva String e Int -- es lo único que necesitan estas tablas.
    private func insertar(_ sql: String, _ valores: [Any]) {
        guard let db else { return }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        for (i, valor) in valores.enumerated() {
            let indice = Int32(i + 1)
            switch valor {
            case let s as String:
                sqlite3_bind_text(stmt, indice, s, -1, SQLITE_TRANSIENT)
            case let n as Int:
                sqlite3_bind_int(stmt, indice, Int32(n))
            default:
                sqlite3_bind_null(stmt, indice)
            }
        }
        sqlite3_step(stmt)
    }
}
