import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var seleccion: UUID?
    @State private var nombrando: Nombrando?

    var body: some View {
        NavigationSplitView {
            barraLateral
                .navigationSplitViewColumnWidth(min: 200, ideal: 240)
        } detail: {
            Group {
                if let i = store.proyectos.firstIndex(where: { $0.id == seleccion }) {
                    ProyectoView(proyecto: $store.proyectos[i])
                        .id(store.proyectos[i].id)
                } else {
                    Text("Selecciona o crea un proyecto")
                        .foregroundStyle(Tema.apagado)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Tema.fondo)
            .safeAreaInset(edge: .bottom, spacing: 0) { barraDetalle }
        }
        .navigationTitle("")
        .toolbarBackground(.hidden, for: .windowToolbar)
        .sheet(item: $nombrando) { n in
            NombreSheet(titulo: n.id == nil ? "Nuevo proyecto" : "Renombrar proyecto",
                        texto: n.texto) { nombre in
                if let id = n.id {
                    if let i = store.proyectos.firstIndex(where: { $0.id == id }) {
                        store.proyectos[i].nombre = nombre
                    }
                } else {
                    nuevo(nombre)
                }
            }
        }
        .onAppear { if seleccion == nil { seleccion = store.proyectos.first?.id } }
    }

    // MARK: Panel lateral

    private var barraLateral: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                if let logo = Tema.logo {
                    Image(nsImage: logo).resizable().scaledToFit().frame(width: 110, height: 110)
                }
                Text("CMDBOARD")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(Tema.champan)
            }
            .padding(.top, 4)
            .padding(.bottom, 10)

            HStack {
                Text("PROYECTOS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Tema.cobre)
                Spacer()
                Button { if let s = seleccion { eliminar(s) } } label: { Image(systemName: "minus") }
                    .disabled(seleccion == nil)
                    .help("Eliminar proyecto")
                Button { nombrando = Nombrando(id: nil, texto: "") } label: { Image(systemName: "plus") }
                    .help("Nuevo proyecto")
            }
            .buttonStyle(EstiloSecundario())
            .focusEffectDisabled()
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(store.proyectos) { p in fila(p) }
                }
                .padding(.horizontal, 10)
            }

            barraPie
        }
        .background(Tema.fondo)
    }

    private func fila(_ p: Proyecto) -> some View {
        let elegido = p.id == seleccion
        return Button { seleccion = p.id } label: {
            Text(p.nombre.isEmpty ? "Sin nombre" : p.nombre)
                .foregroundStyle(elegido ? Tema.ambar : Tema.champan)
                .fontWeight(elegido ? .semibold : .regular)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(elegido ? Tema.naranja.opacity(0.16) : .clear, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(elegido ? Tema.naranja.opacity(0.5) : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Renombrar…") { nombrando = Nombrando(id: p.id, texto: p.nombre) }
            Button("Eliminar", role: .destructive) { eliminar(p.id) }
        }
    }

    // MARK: Barra inferior

    private var cambiosAqui: Bool { seleccion.map { store.hayCambios($0) } ?? false }

    private var estado: String {
        if cambiosAqui { return "Cambios sin aceptar" }
        return store.hayCambios ? "Cambios en otro proyecto" : "Sin cambios"
    }

    private var barraPie: some View {
        HStack {
            Button("Salir") { NSApplication.shared.terminate(nil) }
                .buttonStyle(EstiloSecundario())
            Text(estado)
                .font(.callout)
                .foregroundStyle(store.hayCambios ? Tema.ambar : Tema.apagado)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Tema.fondo)
        .overlay(alignment: .top) { Divider().overlay(Tema.cobre.opacity(0.25)) }
    }

    private var barraDetalle: some View {
        HStack {
            Spacer()
            Button("Descartar cambios") { descartar() }
                .buttonStyle(EstiloSecundario())
                .disabled(!cambiosAqui)
            Button("Aceptar") { if let s = seleccion { store.aceptarCambios(s) } }
                .buttonStyle(EstiloPrimario())
                .disabled(!cambiosAqui)
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
        .background(Tema.fondo)
        .overlay(alignment: .top) { Divider().overlay(Tema.cobre.opacity(0.25)) }
    }

    // MARK: Acciones

    private func descartar() {
        guard let id = seleccion, let p = store.proyectos.first(where: { $0.id == id }) else { return }
        let a = NSAlert()
        a.messageText = "¿Descartar los cambios de «\(p.nombre)»?"
        a.informativeText = "Volverá al estado de la última vez que aceptaste (o de cuando abriste la app). Si es un proyecto nuevo sin aceptar, se eliminará."
        a.addButton(withTitle: "Descartar")
        a.addButton(withTitle: "Cancelar")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        store.descartarCambios(id)
        if !store.proyectos.contains(where: { $0.id == seleccion }) {
            seleccion = store.proyectos.first?.id
        }
    }

    private func nuevo(_ nombre: String) {
        var p = Proyecto()
        p.nombre = nombre
        store.proyectos.append(p)
        seleccion = p.id
    }

    private func eliminar(_ id: UUID) {
        guard let i = store.proyectos.firstIndex(where: { $0.id == id }) else { return }
        let a = NSAlert()
        a.messageText = "¿Eliminar «\(store.proyectos[i].nombre)»?"
        a.informativeText = "Se borrarán sus comandos y enlaces. Esto no se puede deshacer."
        a.addButton(withTitle: "Eliminar")
        a.addButton(withTitle: "Cancelar")
        guard a.runModal() == .alertFirstButtonReturn else { return }
        store.eliminar(id)
        seleccion = store.proyectos.first?.id
    }
}

struct Nombrando: Identifiable {
    let id: UUID?
    var texto: String
}

struct NombreSheet: View {
    let titulo: String
    @State var texto: String
    let aceptar: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private var valido: Bool { !texto.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titulo).font(.headline).foregroundStyle(Tema.champan)
            TextField("Nombre del proyecto", text: $texto)
                .campo()
                .onSubmit(guardar)
            HStack {
                Spacer()
                Button("Cancelar") { dismiss() }
                    .buttonStyle(EstiloSecundario())
                    .keyboardShortcut(.cancelAction)
                Button("Aceptar", action: guardar)
                    .buttonStyle(EstiloPrimario())
                    .keyboardShortcut(.defaultAction)
                    .disabled(!valido)
            }
        }
        .padding(20)
        .frame(width: 340)
        .background(Tema.fondo)
    }

    private func guardar() {
        guard valido else { return }
        aceptar(texto.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}

// MARK: Detalle de proyecto

struct ProyectoView: View {
    @Binding var proyecto: Proyecto
    @State private var copiado: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TextField("Nombre del proyecto", text: $proyecto.nombre)
                    .font(.system(size: 26, weight: .bold))
                    .textFieldStyle(.plain)
                    .foregroundStyle(Tema.champan)
                    .padding(.horizontal, 4)

                DescripcionView(texto: $proyecto.descripcion)

                directorio
                comandos
                documentacion
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var directorio: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder").foregroundStyle(Tema.cobre)
            TextField("Directorio de trabajo (opcional)", text: $proyecto.directorioTrabajo)
                .campo()
            Button("Elegir…") {
                if let r = Acciones.elegirCarpeta() { proyecto.directorioTrabajo = r }
            }
            Button("Copiar cd") { marcarCopiado(nil, "cd \(comillas(proyecto.directorioTrabajo))") }
                .disabled(proyecto.directorioTrabajo.isEmpty)
        }
        .buttonStyle(EstiloSecundario())
    }

    private var comandos: some View {
        VStack(alignment: .leading, spacing: 10) {
            cabecera("Comandos") { proyecto.comandos.append(Comando()) }
            ForEach($proyecto.comandos) { $c in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Etiqueta", text: $c.etiqueta)
                            .font(.headline)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Tema.ambar)
                        Button {
                            marcarCopiado(c.id, c.comando)
                        } label: {
                            Label(copiado == c.id ? "Copiado" : "Copiar",
                                  systemImage: copiado == c.id ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(EstiloPrimario())
                        Button(role: .destructive) {
                            proyecto.comandos.removeAll { $0.id == c.id }
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(EstiloSecundario())
                    }
                    TextField("Comando", text: $c.comando, axis: .vertical)
                        .font(.system(.body, design: .monospaced))
                        .campo()
                    TextField("Nota (opcional)", text: $c.nota)
                        .font(.caption)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Tema.apagado)
                        .padding(.horizontal, 4)
                }
                .tarjeta()
            }
        }
    }

    private var documentacion: some View {
        VStack(alignment: .leading, spacing: 10) {
            cabecera("Documentación") { proyecto.documentacion.append(Enlace()) }
            ForEach($proyecto.documentacion) { $d in
                HStack(spacing: 8) {
                    TextField("Título", text: $d.titulo).campo().frame(maxWidth: 220)
                    TextField("Ruta o URL", text: $d.rutaOUrl).campo()
                    Button("Archivo…") {
                        if let r = Acciones.elegirArchivo() {
                            d.rutaOUrl = r
                            if d.titulo.isEmpty { d.titulo = (r as NSString).lastPathComponent }
                        }
                    }
                    .buttonStyle(EstiloSecundario())
                    Button("Abrir") { Acciones.abrir(d.rutaOUrl) }
                        .buttonStyle(EstiloSecundario())
                        .disabled(d.rutaOUrl.isEmpty)
                    Button(role: .destructive) {
                        proyecto.documentacion.removeAll { $0.id == d.id }
                    } label: { Image(systemName: "trash") }
                    .buttonStyle(EstiloSecundario())
                }
            }
        }
    }

    private func cabecera(_ titulo: String, añadir: @escaping () -> Void) -> some View {
        HStack {
            Text(titulo.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Tema.cobre)
            Rectangle().fill(Tema.cobre.opacity(0.25)).frame(height: 1)
            Button(action: añadir) { Label("Añadir", systemImage: "plus") }
                .buttonStyle(EstiloSecundario())
        }
    }

    private func marcarCopiado(_ id: UUID?, _ texto: String) {
        Acciones.copiar(texto)
        copiado = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiado == id { copiado = nil }
        }
    }

    private func comillas(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
