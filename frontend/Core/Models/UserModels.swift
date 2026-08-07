import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var username: String
    var email: String
}

struct AuthResponse: Codable {
    let token: String
    let user: UserProfile
}
