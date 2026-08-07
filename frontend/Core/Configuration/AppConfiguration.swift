import Foundation

enum AppConfiguration {
    /// Simulator/local Mac default. For a physical iPhone, replace this with your computer's LAN IP.
    /// Example: http://192.168.1.25:8080
    static let apiBaseURL = URL(string: "http://127.0.0.1:8080")!
}
