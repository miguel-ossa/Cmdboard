import SwiftUI

/// Descripción libre: se edita como texto plano y, fuera de edición, las direcciones web
/// (http/https o «www.…») se muestran como enlaces pulsables.
struct DescripcionView: View {
    @Binding var texto: String
    @State private var editando = false
    @FocusState private var foco: Bool

    private var mostrarEditor: Bool {
        editando || foco || texto.isEmpty
    }

    var body: some View {
        Group {
            if mostrarEditor {
                TextField("Descripción del proyecto", text: $texto, axis: .vertical)
                    .lineLimit(3...12)
                    .focused($foco)
                    .campo()
                    .onChange(of: foco) { _, enfocado in
                        if !enfocado { editando = false }
                    }
            } else {
                Text(Self.conEnlaces(texto))
                    .tint(Tema.ambar)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 9)
                    .padding(.trailing, 36)
                    .padding(.vertical, 6)
                    .frame(minHeight: 34, alignment: .topLeading)
                    .background(Tema.campo, in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Tema.cobre.opacity(0.22)))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            editando = true
                            DispatchQueue.main.async { foco = true }
                        } label: { Image(systemName: "pencil") }
                        .buttonStyle(EstiloSecundario())
                        .help("Editar descripción")
                        .padding(4)
                    }
            }
        }
    }

    static func conEnlaces(_ texto: String) -> AttributedString {
        var a = AttributedString(texto)
        a.foregroundColor = Tema.champan
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return a }
        for m in detector.matches(in: texto, range: NSRange(location: 0, length: (texto as NSString).length)) {
            guard let url = m.url, ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  let r = Range(m.range, in: texto),
                  let ar = Range<AttributedString.Index>(r, in: a) else { continue }
            a[ar].link = url
            a[ar].foregroundColor = Tema.ambar
            a[ar].underlineStyle = .single
        }
        return a
    }
}
