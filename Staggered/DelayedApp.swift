import Foundation
import AppKit

struct DelayedApp: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bundlePath: String
    var delaySeconds: Int

    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: bundlePath)
    }
}
