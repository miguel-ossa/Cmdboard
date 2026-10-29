import SwiftUI

@main
struct CmdBoardApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 820, minHeight: 540)
                .preferredColorScheme(.dark)
        }
        .commands {
            CommandGroup(after: .importExport) {
                Button("Exportar configuración…") { store.exportar() }
                Button("Importar configuración…") { store.importar() }
            }
        }
    }
}
