import Foundation
import AppKit

/// Runs at login. Reads saved config and launches each app with its delay.
enum LaunchRunner {
    static func run() {
        // Use the standard UserDefaults for the app's preferences so we
        // read the same domain macOS writes to (avoid nonsensical suite names).
        let defaults = UserDefaults.standard

        let isParallel = defaults.bool(forKey: "launchModeIsParallel")

        guard let data = defaults.data(forKey: "savedDelayedApps"),
              let apps = try? JSONDecoder().decode([DelayedApp].self, from: data),
              !apps.isEmpty else {
            return
        }

        let workspace = NSWorkspace.shared

        func open(_ app: DelayedApp) {
            let url = URL(fileURLWithPath: app.bundlePath)
            // Verify the app still exists before trying to open
            guard FileManager.default.fileExists(atPath: app.bundlePath) else {
                NSLog("[staggered] Skipping missing app: %@", app.bundlePath)
                return
            }
            let config = NSWorkspace.OpenConfiguration()
            // Don't activate apps when launching at login — keep launches silent
            config.activates = false
            // Use a semaphore so we know the open call was dispatched
            // before we sleep/move to the next one
            let sem = DispatchSemaphore(value: 0)
                workspace.openApplication(at: url, configuration: config) { _, error in
                if let error = error {
                    NSLog("[staggered] Failed to open %@: %@", app.name, error.localizedDescription)
                }
                sem.signal()
            }
            sem.wait()
        }

        if isParallel {
            let group = DispatchGroup()
            for app in apps {
                group.enter()
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(app.delaySeconds)) {
                    open(app)
                    group.leave()
                }
            }
            group.wait()

        } else {
            // Sequence: treat each app's `delaySeconds` as the delay after
            // the previous app (cumulative). Iterate in the saved order.
            for app in apps {
                if app.delaySeconds > 0 {
                    Thread.sleep(forTimeInterval: TimeInterval(app.delaySeconds))
                }
                open(app)
            }
        }
    }
}
