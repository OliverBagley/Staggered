import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Controls whether the app should quit after the last window closes.
    var terminateAfterLastWindowClosed = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard CommandLine.arguments.contains("--login") else { return }

        Task.detached(priority: .userInitiated) {
            LaunchRunner.run()
            await MainActor.run {
                NSApp.terminate(nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        terminateAfterLastWindowClosed
    }
}

struct StaggeredApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let isLogin = CommandLine.arguments.contains("--login")

    init() {
        appDelegate.terminateAfterLastWindowClosed = !isLogin
    }

    var body: some Scene {
        WindowGroup {
            if isLogin {
                EmptyView()
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
