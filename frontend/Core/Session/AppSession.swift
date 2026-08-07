import Foundation

/// Single source of truth for authentication state across the SwiftUI app.
@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var user: UserProfile?
    @Published private(set) var isRestoring = true

    private let storage: AppStorageManager
    private let authService: AuthService

    init(storage: AppStorageManager = AppStorageManager(), authService: AuthService = AuthService()) {
        self.storage = storage
        self.authService = authService
        self.token = storage.authToken()
    }

    var isAuthenticated: Bool { token != nil && user != nil }

    func restore() async {
        defer { isRestoring = false }
        guard let token else { return }
        do {
            user = try await authService.profile(token: token)
        } catch {
            clearLocalSession()
        }
    }

    func signup(username: String, email: String, password: String) async throws {
        let response = try await authService.signup(username: username, email: email, password: password)
        accept(response)
    }

    func login(email: String, password: String) async throws {
        let response = try await authService.login(email: email, password: password)
        accept(response)
    }

    func updateProfile(username: String, email: String) async throws {
        guard let token else { return }
        user = try await authService.updateProfile(username: username, email: email, token: token)
    }

    func changePassword(current: String, new: String) async throws {
        guard let token else { return }
        try await authService.changePassword(current: current, new: new, token: token)
        // The backend deliberately invalidates all tokens after a password change.
        clearLocalSession()
    }

    func logout() async {
        if let token { try? await authService.logout(token: token) }
        clearLocalSession()
    }

    private func accept(_ response: AuthResponse) {
        token = response.token
        user = response.user
        storage.saveAuthToken(response.token)
    }

    private func clearLocalSession() {
        token = nil
        user = nil
        storage.clearAuthToken()
    }
}
