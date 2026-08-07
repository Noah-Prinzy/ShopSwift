import Vapor

/// Central helper for environment variables so configuration code stays readable.
enum AppEnvironment {
    static func value(_ key: String, default defaultValue: String? = nil) -> String? {
        Environment.get(key) ?? defaultValue
    }

    /// Returns a required environment value or fails startup with a clear message.
    static func required(_ key: String) throws -> String {
        guard let value = Environment.get(key), !value.isEmpty else {
            throw Abort(.internalServerError, reason: "Missing required environment variable: \(key)")
        }
        return value
    }
}
