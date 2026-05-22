import Foundation
import AppKit

/// Runs at login. Reads saved config and launches each app with its delay.
enum LaunchRunner {
    static func run() {
        // Use the explicit suite name matching the bundle ID to guarantee
        // we read from the same UserDefaults domain the GUI wrote.
        let defaults = UserDefaults(suiteName: "com.oliverbagley.staggered")
                    ?? UserDefaults.standard

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
            config.activates = true
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
            // Sequence: sort ascending, sleep the delta between each
            let sorted = apps.sorted { $0.delaySeconds < $1.delaySeconds }
            var previous = 0
            for app in sorted {
                let interval = app.delaySeconds - previous
                previous = app.delaySeconds
                if interval > 0 {
                    Thread.sleep(forTimeInterval: TimeInterval(interval))
                }
                open(app)
            }
        }
    }
}
