import SwiftUI
import AppKit

@main
struct StaggeredApp: App {
    init() {
        if CommandLine.arguments.contains("--login") {
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.prohibited)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 540, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
