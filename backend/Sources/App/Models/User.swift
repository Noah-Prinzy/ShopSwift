import Fluent
import Vapor

/// Database representation of a registered shopper.
/// `passwordHash` is never returned directly to the frontend.
final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "created_at")
    var createdAt: Date

    @Field(key: "updated_at")
    var updatedAt: Date

    init() {}

    init(id: UUID? = nil, username: String, email: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// Safe user information that may be sent over the API.
struct UserResponse: Content {
    let id: UUID
    let username: String
    let email: String

    init(user: User) throws {
        self.id = try user.requireID()
        self.username = user.username
        self.email = user.email
    }
}

// This conformance makes User a valid Vapor authentication principal.
// Login is still implemented manually so bcrypt verification can use Vapor's async password API.
extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: passwordHash)
    }
}
