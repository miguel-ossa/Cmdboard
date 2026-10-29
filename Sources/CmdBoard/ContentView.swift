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
    @State private var editando: Set<UUID> = []

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

    private func alternarEdicion(_ id: UUID) {
        if editando.contains(id) { editando.remove(id) } else { editando.insert(id) }
    }

    private var comandos: some View {
        VStack(alignment: .leading, spacing: 10) {
            cabecera("Comandos") {
                let c = Comando()
                proyecto.comandos.append(c)
                editando.insert(c.id)
            }
            ForEach($proyecto.comandos) { $c in
                let enEdicion = editando.contains(c.id)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if enEdicion {
                            TextField("Etiqueta", text: $c.etiqueta)
                                .font(.headline)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Tema.ambar)
                        } else {
                            Text(c.etiqueta.isEmpty ? "Sin etiqueta" : c.etiqueta)
                                .font(.headline)
                                .foregroundStyle(c.etiqueta.isEmpty ? Tema.apagado : Tema.ambar)
                            Spacer()
                        }
                        Button {
                            marcarCopiado(c.id, c.comando)
                        } label: {
                            Label(copiado == c.id ? "Copiado" : "Copiar",
                                  systemImage: copiado == c.id ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(EstiloPrimario())
                        .disabled(c.comando.isEmpty)
                        botonEdicion(c.id, enEdicion)
                        Button(role: .destructive) {
                            borrar(c.etiqueta.isEmpty ? "este comando" : "«\(c.etiqueta)»",
                                   vacio: c.etiqueta.isEmpty && c.comando.isEmpty && c.nota.isEmpty) {
                                proyecto.comandos.removeAll { $0.id == c.id }
                            }
                        } label: { Image(systemName: "trash") }
                        .buttonStyle(EstiloSecundario())
                        .help("Eliminar comando")
                    }
                    if enEdicion {
                        EditorMultilinea(texto: $c.comando, placeholder: "Comando (Intro añade otra línea)", mono: true)
                        TextField("Nota (opcional)", text: $c.nota)
                            .font(.caption)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Tema.apagado)
                            .padding(.horizontal, 4)
                    } else {
                        Text(c.comando)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Tema.champan)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Tema.campo, in: RoundedRectangle(cornerRadius: 7))
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Tema.cobre.opacity(0.22)))
                        if !c.nota.isEmpty {
                            Text(c.nota)
                                .font(.caption)
                                .foregroundStyle(Tema.apagado)
                                .padding(.horizontal, 4)
                        }
                    }
                }
                .tarjeta()
            }
        }
    }

    private var documentacion: some View {
        VStack(alignment: .leading, spacing: 10) {
            cabecera("Documentación") {
                let d = Enlace()
                proyecto.documentacion.append(d)
                editando.insert(d.id)
            }
            ForEach($proyecto.documentacion) { $d in
                let enEdicion = editando.contains(d.id)
                if enEdicion {
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
                        botonEdicion(d.id, true)
                        botonBorrarDocumento($d.wrappedValue)
                    }
                } else {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(d.titulo.isEmpty ? "Sin título" : d.titulo)
                                .foregroundStyle(d.titulo.isEmpty ? Tema.apagado : Tema.champan)
                            Text(d.rutaOUrl)
                                .font(.caption)
                                .foregroundStyle(Tema.apagado)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button("Abrir") { Acciones.abrir(d.rutaOUrl) }
                            .buttonStyle(EstiloSecundario())
                            .disabled(d.rutaOUrl.isEmpty)
                        botonEdicion(d.id, false)
                        botonBorrarDocumento(d)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Tema.panel, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Tema.cobre.opacity(0.18)))
                }
            }
        }
    }

    private func botonBorrarDocumento(_ d: Enlace) -> some View {
        Button(role: .destructive) {
            borrar(d.titulo.isEmpty ? "este documento" : "«\(d.titulo)»",
                   vacio: d.titulo.isEmpty && d.rutaOUrl.isEmpty) {
                proyecto.documentacion.removeAll { $0.id == d.id }
            }
        } label: { Image(systemName: "trash") }
        .buttonStyle(EstiloSecundario())
        .help("Eliminar documento")
    }

    /// Las entradas vacías se borran sin preguntar; el resto, con confirmación.
    private func borrar(_ nombre: String, vacio: Bool, accion: () -> Void) {
        if !vacio {
            let a = NSAlert()
            a.messageText = "¿Eliminar \(nombre)?"
            a.informativeText = "Podrás recuperarla con «Descartar cambios» hasta que pulses «Aceptar»."
            a.addButton(withTitle: "Eliminar")
            a.addButton(withTitle: "Cancelar")
            guard a.runModal() == .alertFirstButtonReturn else { return }
        }
        accion()
    }

    private func botonEdicion(_ id: UUID, _ enEdicion: Bool) -> some View {
        Button { alternarEdicion(id) } label: {
            if enEdicion { Text("Listo") } else { Image(systemName: "pencil") }
        }
        .buttonStyle(EstiloSecundario())
        .help(enEdicion ? "Terminar de editar" : "Editar")
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
