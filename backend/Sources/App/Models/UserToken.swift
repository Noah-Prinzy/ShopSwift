import Fluent
import Vapor

/// Opaque bearer token stored in PostgreSQL after login/signup.
/// Protected API routes use this model's authenticator to resolve the current User.
final class UserToken: Model, Content, @unchecked Sendable {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "user_id")
    var user: User

    @Field(key: "expires_at")
    var expiresAt: Date

    @Field(key: "created_at")
    var createdAt: Date

    init() {}

    init(id: UUID? = nil, value: String, userID: UUID, expiresAt: Date) {
        self.id = id
        self.value = value
        self.$user.id = userID
        self.expiresAt = expiresAt
        self.createdAt = Date()
    }

    static func generate(for user: User) throws -> UserToken {
        // Generate 256 bits of random data and encode it for use in the Authorization header.
        let value = [UInt8].random(count: 32).base64
        return UserToken(
            value: value,
            userID: try user.requireID(),
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 7) // 7 days
        )
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<UserToken, Field<String>> { \.$value }
    static var userKey: KeyPath<UserToken, Parent<User>> { \.$user }

    var isValid: Bool {
        expiresAt > Date()
    }
}
