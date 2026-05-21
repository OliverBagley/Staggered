import Foundation
import AppKit

/// Runs at login (--login flag). Reads saved config from UserDefaults,
/// launches each app with its configured delay, then exits.
enum LaunchRunner {
    static func run() {
        let defaults = UserDefaults.standard
        let isParallel = defaults.bool(forKey: "launchModeIsParallel")

        guard let data = defaults.data(forKey: "savedDelayedApps"),
              let apps = try? JSONDecoder().decode([DelayedApp].self, from: data),
              !apps.isEmpty else {
            return // Nothing configured, exit cleanly
        }

        let workspace = NSWorkspace.shared

        func open(_ app: DelayedApp) {
            let url = URL(fileURLWithPath: app.bundlePath)
            workspace.openApplication(
                at: url,
                configuration: NSWorkspace.OpenConfiguration(),
                completionHandler: nil
            )
        }

        if isParallel {
            // Each timer fires independently from t=0
            let group = DispatchGroup()
            for app in apps {
                group.enter()
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(app.delaySeconds)) {
                    open(app)
                    group.leave()
                }
            }
            // Block until all timers have fired, then give a small buffer
            group.wait()
            Thread.sleep(forTimeInterval: 2)

        } else {
            // Sequence: sort by delay, sleep the delta between each
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
            Thread.sleep(forTimeInterval: 2)
        }
    }
}
