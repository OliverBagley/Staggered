import SwiftUI
import AppKit

@main
struct StartupDelayerApp: App {
    init() {
        if CommandLine.arguments.contains("--login") {
            // Launched at login — run silently, no UI, no dock icon
            NSApp.setActivationPolicy(.prohibited)
            LaunchRunner.run()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 540, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
