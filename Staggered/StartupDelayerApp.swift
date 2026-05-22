import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Controls whether the app should quit after the last window closes.
    var terminateAfterLastWindowClosed = true

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        terminateAfterLastWindowClosed
    }
}

struct StaggeredApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
        let isLogin = CommandLine.arguments.contains("--login")
        appDelegate.terminateAfterLastWindowClosed = !isLogin
    }

    var body: some Scene {
        WindowGroup {
            if CommandLine.arguments.contains("--login") {
                LauncherRunnerView()
                    .frame(width: 1, height: 1)
            } else {
                ContentView()
                    .frame(minWidth: 540, minHeight: 500)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
