import AppKit
import SwiftUI

/// Paleta sacada de logo_direct_design.png: negro cálido, champán/cobre y naranja brillante.
enum Tema {
    static let fondo = Color(red: 0.039, green: 0.035, blue: 0.027)       // #0A0907
    static let panel = Color(red: 0.086, green: 0.075, blue: 0.063)       // #161310
    static let campo = Color(red: 0.055, green: 0.047, blue: 0.039)       // #0E0C0A
    static let elevado = Color(red: 0.140, green: 0.118, blue: 0.098)     // #231E19
    static let cobre = Color(red: 0.694, green: 0.537, blue: 0.404)       // #B18967
    static let champan = Color(red: 0.914, green: 0.839, blue: 0.769)     // #E9D6C4
    static let apagado = Color(red: 0.604, green: 0.545, blue: 0.478)     // #9A8B7A
    static let naranja = Color(red: 1.0, green: 0.541, blue: 0.165)       // #FF8A2A
    static let ambar = Color(red: 0.988, green: 0.690, blue: 0.322)       // #FCB052

    static let degradadoNaranja = LinearGradient(colors: [ambar, naranja], startPoint: .top, endPoint: .bottom)
    static let degradadoCobre = LinearGradient(colors: [cobre.opacity(0.55), cobre.opacity(0.15)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)

    static var logo: NSImage? {
        Bundle.main.url(forResource: "logo", withExtension: "png").flatMap { NSImage(contentsOf: $0) }
    }
}

struct EstiloSecundario: ButtonStyle {
    @Environment(\.isEnabled) private var activo

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .foregroundStyle(Tema.champan)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(configuration.isPressed ? Tema.cobre.opacity(0.25) : Tema.elevado,
                        in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Tema.cobre.opacity(0.35)))
            .opacity(activo ? 1 : 0.4)
    }
}

struct EstiloPrimario: ButtonStyle {
    @Environment(\.isEnabled) private var activo

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color(red: 0.10, green: 0.05, blue: 0.02))
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Tema.degradadoNaranja, in: RoundedRectangle(cornerRadius: 7))
            .brightness(configuration.isPressed ? -0.12 : 0)
            .shadow(color: Tema.naranja.opacity(activo ? 0.35 : 0), radius: 8)
            .opacity(activo ? 1 : 0.4)
    }
}

struct Campo: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .foregroundStyle(Tema.champan)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Tema.campo, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Tema.cobre.opacity(0.22)))
    }
}

extension View {
    func campo() -> some View { modifier(Campo()) }

    func tarjeta() -> some View {
        padding(12)
            .background(Tema.panel, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Tema.degradadoCobre, lineWidth: 1))
    }
}
