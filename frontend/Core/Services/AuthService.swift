import Foundation

struct SignUpPayload: Encodable {
    let username: String
    let email: String
    let password: String
}

struct LoginPayload: Encodable {
    let email: String
    let password: String
}

struct UpdateProfilePayload: Encodable {
    let username: String?
    let email: String?
}

struct ChangePasswordPayload: Encodable {
    let currentPassword: String
    let newPassword: String
}

struct AuthService {
    let apiClient: APIClientProtocol
    private let encoder = JSONEncoder()

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func signup(username: String, email: String, password: String) async throws -> AuthResponse {
        let body = try encoder.encode(SignUpPayload(username: username, email: email, password: password))
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/auth/signup", method: .post, body: body),
            as: AuthResponse.self,
            token: nil
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = try encoder.encode(LoginPayload(email: email, password: password))
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/auth/login", method: .post, body: body),
            as: AuthResponse.self,
            token: nil
        )
    }

    func profile(token: String) async throws -> UserProfile {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/profile"),
            as: UserProfile.self,
            token: token
        )
    }

    func updateProfile(username: String, email: String, token: String) async throws -> UserProfile {
        let body = try encoder.encode(UpdateProfilePayload(username: username, email: email))
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/profile", method: .patch, body: body),
            as: UserProfile.self,
            token: token
        )
    }

    func changePassword(current: String, new: String, token: String) async throws {
        let body = try encoder.encode(ChangePasswordPayload(currentPassword: current, newPassword: new))
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/profile/password", method: .patch, body: body),
            token: token
        )
    }

    func logout(token: String) async throws {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/auth/logout", method: .post),
            token: token
        )
    }
}
