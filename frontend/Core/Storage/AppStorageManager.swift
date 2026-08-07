import Foundation

/// Small persistence wrapper used to keep the bearer token between app launches.
final class AppStorageManager {
    private let defaults: UserDefaults
    private let authTokenKey = "shopswift.authToken"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveAuthToken(_ token: String) {
        defaults.set(token, forKey: authTokenKey)
    }

    func authToken() -> String? {
        defaults.string(forKey: authTokenKey)
    }

    func clearAuthToken() {
        defaults.removeObject(forKey: authTokenKey)
    }
}
