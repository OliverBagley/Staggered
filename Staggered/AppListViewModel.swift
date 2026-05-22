import Foundation
import AppKit

class AppListViewModel: ObservableObject {
    @Published var apps: [DelayedApp] = []
    @Published var isParallel: Bool = false
    @Published var loginItemEnabled: Bool = false
    @Published var errorMessage: String? = nil

    private let appsKey = "savedDelayedApps"
    private let modeKey = "launchModeIsParallel"
    private let plistLabel = "com.oliverbagley.staggered.launcher"

    private let defaults = UserDefaults(suiteName: "com.oliverbagley.staggered")
                        ?? UserDefaults.standard

    // Path to the LaunchAgent plist we manage in the user's Library
    private var launchAgentPlistURL: URL {
        let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        return launchAgentsDir.appendingPathComponent("\(plistLabel).plist")
    }

    // Absolute path to this running app's executable
    private var executablePath: String {
        Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
    }

    init() {
        load()
        refreshLoginItemStatus()
    }

    // MARK: - App List

    func addApp(url: URL) {
        let name = url.deletingPathExtension().lastPathComponent
        let path = url.path
        guard !apps.contains(where: { $0.bundlePath == path }) else { return }
        apps.append(DelayedApp(name: name, bundlePath: path, delaySeconds: 1))
        save()
    }

    func removeApp(at offsets: IndexSet) {
        apps.remove(atOffsets: offsets)
        save()
    }

    func removeApp(id: UUID) {
        apps.removeAll { $0.id == id }
        save()
    }

    func moveApp(from source: IndexSet, to destination: Int) {
        apps.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func save() {
        if let data = try? JSONEncoder().encode(apps) {
            defaults.set(data, forKey: appsKey)
        }
        defaults.set(isParallel, forKey: modeKey)
        defaults.synchronize()
    }

    func load() {
        if let data = defaults.data(forKey: appsKey),
           let decoded = try? JSONDecoder().decode([DelayedApp].self, from: data) {
            apps = decoded
        }
        isParallel = defaults.bool(forKey: modeKey)
    }

    // MARK: - Login Item via LaunchAgent plist

    func refreshLoginItemStatus() {
        loginItemEnabled = FileManager.default.fileExists(atPath: launchAgentPlistURL.path)
    }

    func toggleLoginItem() {
        if loginItemEnabled {
            unregisterLaunchAgent()
        } else {
            registerLaunchAgent()
        }
    }

    private func registerLaunchAgent() {
        let launchAgentsDir = launchAgentPlistURL.deletingLastPathComponent()

        // Create ~/Library/LaunchAgents if it doesn't exist
        do {
            try FileManager.default.createDirectory(
                at: launchAgentsDir,
                withIntermediateDirectories: true
            )
        } catch {
            errorMessage = "Could not create LaunchAgents directory: \(error.localizedDescription)"
            return
        }

        // Build the plist dictionary
        let plist: [String: Any] = [
            "Label": plistLabel,
            "ProgramArguments": [executablePath, "--login"],
            "RunAtLoad": true,
            "StandardOutPath": "/tmp/staggered.log",
            "StandardErrorPath": "/tmp/staggered.log"
        ]

        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )
            try data.write(to: launchAgentPlistURL, options: .atomic)
        } catch {
            errorMessage = "Could not write LaunchAgent plist: \(error.localizedDescription)"
            return
        }

        // Load it into launchd immediately so it's active without a reboot
        runLaunchctl("load", launchAgentPlistURL.path)
        loginItemEnabled = true
    }

    private func unregisterLaunchAgent() {
        // Unload from launchd first
        runLaunchctl("unload", launchAgentPlistURL.path)

        // Remove the plist
        do {
            try FileManager.default.removeItem(at: launchAgentPlistURL)
        } catch {
            errorMessage = "Could not remove LaunchAgent plist: \(error.localizedDescription)"
            return
        }
        loginItemEnabled = false
    }

    @discardableResult
    private func runLaunchctl(_ verb: String, _ path: String) -> Bool {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = [verb, path]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
}
