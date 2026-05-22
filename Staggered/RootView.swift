import SwiftUI
import AppKit

struct RootView: View {
    var body: some View {
        if CommandLine.arguments.contains("--login") {
            LauncherRunnerView()
        } else {
            ContentView()
        }
    }
}

struct LauncherRunnerView: View {
    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onAppear {
                Task.detached(priority: .userInitiated) {
                    LaunchRunner.run()
                    await MainActor.run {
                        NSApp.terminate(nil)
                    }
                }
            }
    }
}
