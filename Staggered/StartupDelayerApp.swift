import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Controls whether the app should quit after the last window closes.
    var terminateAfterLastWindowClosed = true

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        terminateAfterLastWindowClosed
    }
}

@main
struct StaggeredApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        let isLogin = CommandLine.arguments.contains("--login")

        // When launched as a login item we must not appear in the Dock.
        if isLogin {
            NSApplication.shared.setActivationPolicy(.prohibited)
            // Don't keep the app alive when windows close for login runs
            appDelegate.terminateAfterLastWindowClosed = false
        } else {
            // For normal (user) launches, quit when last window closes
            appDelegate.terminateAfterLastWindowClosed = true
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
