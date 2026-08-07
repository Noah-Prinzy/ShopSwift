import Vapor

/// Payload used when a shopper creates an account.
struct SignUpRequest: Content, Validatable {
    let username: String
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .count(3...30))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...100))
    }
}

struct LoginRequest: Content, Validatable {
    let email: String
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}

/// Returned after signup/login. The frontend stores `token` and sends it as Bearer authentication.
struct AuthResponse: Content {
    let token: String
    let user: UserResponse
}

struct UpdateProfileRequest: Content {
    let username: String?
    let email: String?
}

struct ChangePasswordRequest: Content, Validatable {
    let currentPassword: String
    let newPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("currentPassword", as: String.self, is: !.empty)
        validations.add("newPassword", as: String.self, is: .count(8...100))
    }
}
