import Foundation
import AppKit
import ServiceManagement

class AppListViewModel: ObservableObject {
    @Published var apps: [DelayedApp] = []
    @Published var isParallel: Bool = false
    @Published var loginItemEnabled: Bool = false
    @Published var errorMessage: String? = nil

    private let appsKey = "savedDelayedApps"
    private let modeKey = "launchModeIsParallel"

    // SMAppService registers this app itself as the login item,
    // passing --login so the app knows to run headlessly.
    private var service: SMAppService {
        .mainApp
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
        apps.append(DelayedApp(name: name, bundlePath: path, delaySeconds: 5))
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
            UserDefaults.standard.set(data, forKey: appsKey)
        }
        UserDefaults.standard.set(isParallel, forKey: modeKey)
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: appsKey),
           let decoded = try? JSONDecoder().decode([DelayedApp].self, from: data) {
            apps = decoded
        }
        isParallel = UserDefaults.standard.bool(forKey: modeKey)
    }

    // MARK: - Login Item

    func refreshLoginItemStatus() {
        loginItemEnabled = service.status == .enabled
    }

    func toggleLoginItem() {
        do {
            if loginItemEnabled {
                try service.unregister()
                loginItemEnabled = false
            } else {
                try service.register()
                loginItemEnabled = true
            }
        } catch {
            errorMessage = "Could not update Login Item: \(error.localizedDescription)\n\nMake sure the app is in /Applications."
            refreshLoginItemStatus() // revert toggle to actual state
        }
    }
}
