import Foundation

enum Validation {
    static func isValidEmail(_ value: String) -> Bool {
        value.contains("@") && value.contains(".")
    }
}
