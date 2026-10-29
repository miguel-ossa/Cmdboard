import SwiftUI

/// Grupo de la sección «Navegador»: pestañas guardadas con miniatura y botón para abrirlas todas.
struct NavegadorView: View {
    @Binding var grupo: GrupoNavegador
    @StateObject private var miniaturas = Miniaturas.compartido
    @State private var editando: Set<UUID> = []
    @State private var urlAlEditar: [UUID: String] = [:]
    @State private var arrastrando: UUID?

    private let columnas = [GridItem(.adaptive(minimum: 230, maximum: 320), spacing: 14, alignment: .top)]

    private var urls: [URL] { grupo.pestanas.compactMap { Miniaturas.url($0.url) } }

    var body: some View {
        ScrollView {
            contenido
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var contenido: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Nombre del grupo", text: $grupo.nombre)
                .font(.system(size: 26, weight: .bold))
                .textFieldStyle(.plain)
                .foregroundStyle(Tema.champan)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .frame(minHeight: 44)

            HStack(spacing: 10) {
                Image(systemName: "safari").foregroundStyle(Tema.cobre)
                Picker("Navegador", selection: $grupo.navegador) {
                    ForEach(Navegador.allCases) { Text($0.nombre).tag($0) }
                }
                .labelsHidden()
                .frame(width: 130)
                Button {
                    Acciones.abrirPestanas(urls, en: grupo.navegador)
                } label: { Label("Abrir pestañas", systemImage: "arrow.up.forward.app") }
                    .buttonStyle(EstiloPrimario())
                    .disabled(urls.isEmpty || !Acciones.instalado(grupo.navegador))
                if !Acciones.instalado(grupo.navegador) {
                    Text("\(grupo.navegador.nombre) no está instalado")
                        .font(.caption).foregroundStyle(Tema.ambar)
                }
                Spacer()
            }

            HStack {
                Text("PESTAÑAS")
                    .font(.system(size: 12, weight: .semibold)).tracking(2)
                    .foregroundStyle(Tema.cobre)
                Rectangle().fill(Tema.cobre.opacity(0.25)).frame(height: 1)
                Button {
                    let p = Pestana()
                    grupo.pestanas.append(p)
                    editando.insert(p.id)
                    urlAlEditar[p.id] = ""
                } label: { Label("Añadir", systemImage: "plus") }
                    .buttonStyle(EstiloSecundario())
            }

            LazyVGrid(columns: columnas, spacing: 14) {
                ForEach($grupo.pestanas) { $p in
                    tarjetaPestana($p)
                        .onDrop(of: [.text], delegate: Reordenar(destino: p.id, lista: $grupo.pestanas, arrastrando: $arrastrando))
                }
            }
        }
    }

    // MARK: Tarjeta

    private func tarjetaPestana(_ p: Binding<Pestana>) -> some View {
        let v = p.wrappedValue
        let enEdicion = editando.contains(v.id)
        return VStack(alignment: .leading, spacing: 8) {
            miniatura(v)
                .contentShape(Rectangle())
                .onTapGesture { if !enEdicion { abrir(v) } }
                .help(enEdicion ? "" : "Abrir en \(grupo.navegador.nombre)")
            if enEdicion {
                TextField("Título", text: p.titulo).campo()
                TextField("URL", text: p.url).campo()
                TextField("Usuario (opcional, nunca contraseñas)", text: p.usuarioLogin).campo()
                Toggle("Requiere login", isOn: p.requiereLogin)
                    .toggleStyle(.checkbox).foregroundStyle(Tema.champan)
                HStack {
                    Button { regenerar(p) } label: { Label("Regenerar miniatura", systemImage: "camera") }
                        .buttonStyle(EstiloSecundario())
                        .disabled(Miniaturas.url(v.url) == nil || miniaturas.capturando.contains(v.id))
                    abrirBoton(v)
                    Spacer()
                    Button("Listo") { terminarEdicion(p) }.buttonStyle(EstiloSecundario())
                    borrarBoton(v)
                }
            } else {
                Text(v.titulo.isEmpty ? "Sin título" : v.titulo)
                    .foregroundStyle(v.titulo.isEmpty ? Tema.apagado : Tema.champan)
                    .lineLimit(2)
                if !v.usuarioLogin.isEmpty {
                    Label(v.usuarioLogin, systemImage: "person")
                        .font(.caption).foregroundStyle(Tema.apagado).lineLimit(1)
                }
                HStack {
                    abrirBoton(v)
                    Spacer()
                    Button {
                        editando.insert(v.id)
                        urlAlEditar[v.id] = v.url
                    } label: { Image(systemName: "pencil") }
                        .buttonStyle(EstiloSecundario()).help("Editar")
                    borrarBoton(v)
                }
            }
        }
        .tarjeta()
        .onDrag {
            arrastrando = v.id
            return NSItemProvider(object: v.id.uuidString as NSString)
        } preview: {
            Text(v.titulo.isEmpty ? "Sin título" : v.titulo)
                .padding(8).background(Tema.panel, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func abrirBoton(_ v: Pestana) -> some View {
        Button { abrir(v) } label: { Label("Abrir", systemImage: "arrow.up.forward") }
            .buttonStyle(EstiloSecundario())
            .disabled(Miniaturas.url(v.url) == nil || !Acciones.instalado(grupo.navegador))
            .help("Abrir en \(grupo.navegador.nombre)")
    }

    private func abrir(_ v: Pestana) {
        if let u = Miniaturas.url(v.url) { Acciones.abrirPestanas([u], en: grupo.navegador) }
    }

    private func miniatura(_ v: Pestana) -> some View {
        ZStack {
            Tema.campo
            if let img = miniaturas.imagen(v.miniatura) {
                Image(nsImage: img).resizable().scaledToFill()
            } else if miniaturas.capturando.contains(v.id) {
                ProgressView().controlSize(.small)
            } else {
                Image(systemName: "photo").font(.title2).foregroundStyle(Tema.apagado)
            }
        }
        .id(miniaturas.version)
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tema.cobre.opacity(0.22)))
        .overlay(alignment: .topTrailing) {
            if v.requiereLogin {
                Image(systemName: "lock.fill")
                    .font(.caption).foregroundStyle(Tema.ambar)
                    .padding(6).background(.black.opacity(0.65), in: Circle())
                    .padding(6).help("Requiere login")
            }
        }
    }

    private func borrarBoton(_ v: Pestana) -> some View {
        Button(role: .destructive) {
            if !(v.titulo.isEmpty && v.url.isEmpty) {
                let a = NSAlert()
                a.messageText = "¿Eliminar \(v.titulo.isEmpty ? "esta pestaña" : "«\(v.titulo)»")?"
                a.informativeText = "Podrás recuperarla con «Descartar cambios» hasta que pulses «Aceptar»."
                a.addButton(withTitle: "Eliminar")
                a.addButton(withTitle: "Cancelar")
                guard a.runModal() == .alertFirstButtonReturn else { return }
            }
            grupo.pestanas.removeAll { $0.id == v.id }
        } label: { Image(systemName: "trash") }
        .buttonStyle(EstiloSecundario())
        .help("Eliminar pestaña")
    }

    // MARK: Acciones

    /// Al terminar de editar se captura la miniatura si es nueva o si cambió la URL.
    private func terminarEdicion(_ p: Binding<Pestana>) {
        let v = p.wrappedValue
        editando.remove(v.id)
        let antes = urlAlEditar.removeValue(forKey: v.id) ?? ""
        if Miniaturas.url(v.url) != nil, v.miniatura.isEmpty || v.url != antes { regenerar(p) }
    }

    private func regenerar(_ p: Binding<Pestana>) {
        let id = p.wrappedValue.id, url = p.wrappedValue.url
        Task {
            guard let r = await miniaturas.capturar(id: id, url: url),
                  let i = grupo.pestanas.firstIndex(where: { $0.id == id }) else { return }
            grupo.pestanas[i].miniatura = r.archivo
            if grupo.pestanas[i].titulo.isEmpty { grupo.pestanas[i].titulo = r.titulo }
        }
    }
}
