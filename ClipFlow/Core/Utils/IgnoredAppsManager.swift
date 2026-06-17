import Foundation

struct IgnoredAppsManager {
    private static let key = "IgnoredBundleIDs"
    
    static var ignoredIDs: [String] {
        get { UserDefaults.standard.stringArray(forKey: key) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
    
    static func isIgnored(_ bundleID: String) -> Bool {
        ignoredIDs.contains(bundleID)
    }
    
    static func toggle(_ bundleID: String) {
        var current = ignoredIDs
        if let index = current.firstIndex(of: bundleID) {
            current.remove(at: index)
        } else {
            current.append(bundleID)
        }
        ignoredIDs = current
    }
}
