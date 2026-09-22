import Foundation

enum SBX {
    static func containerURL(forBundleIdentifier bundleID: String) -> URL? {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent(bundleID, isDirectory: true)
    }

    static func containerPath(forBundleIdentifier bundleID: String) -> String? {
        containerURL(forBundleIdentifier: bundleID)?.path
    }

    static func applicationSupportURL() -> URL? {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first
    }

    static func documentsURL() -> URL? {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
    }
}