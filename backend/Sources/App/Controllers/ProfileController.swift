import Fluent
import Vapor

/// Authenticated account-management endpoints requested for Phase 1.
///
/// Short notes:
/// - Requires bearer auth via `UserToken`.
/// - `update` validates uniqueness and normalizes inputs before saving.
struct ProfileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let profile = routes
            .grouped("api", "v1", "profile")
            .grouped(UserToken.authenticator())

        profile.get(use: show)
        profile.patch(use: update)
        profile.patch("password", use: changePassword)
    }

    // GET /api/v1/profile
    // Returns the current authenticated user's profile DTO.
    func show(req: Request) async throws -> UserResponse {
        try UserResponse(user: req.auth.require(User.self))
    }

    // PATCH /api/v1/profile
    // Updates username/email after basic validation and uniqueness checks.
    func update(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(UpdateProfileRequest.self)

        if let rawUsername = input.username?.trimmingCharacters(in: .whitespacesAndNewlines), !rawUsername.isEmpty {
            let newUsername = rawUsername.lowercased()
            guard newUsername.count >= 3 else {
                throw Abort(.badRequest, reason: "Username must contain at least 3 characters.")
            }
            if let existing = try await User.query(on: req.db).filter(\.$username == newUsername).first(),
               try existing.requireID() != user.requireID() {
                throw Abort(.conflict, reason: "That username is already taken.")
            }
            user.username = newUsername
        }

        if let rawEmail = input.email?.trimmingCharacters(in: .whitespacesAndNewlines), !rawEmail.isEmpty {
            let newEmail = rawEmail.lowercased()
            guard newEmail.contains("@"), newEmail.contains(".") else {
                throw Abort(.badRequest, reason: "Please provide a valid email address.")
            }
            if let existing = try await User.query(on: req.db).filter(\.$email == newEmail).first(),
               try existing.requireID() != user.requireID() {
                throw Abort(.conflict, reason: "An account with that email already exists.")
            }
            user.email = newEmail
        }

        user.updatedAt = Date()
        try await user.save(on: req.db)
        return try UserResponse(user: user)
    }

    // PATCH /api/v1/profile/password
    // Changes the user's password after verifying the current one and invalidates existing tokens.
    func changePassword(req: Request) async throws -> HTTPStatus {
        try ChangePasswordRequest.validate(content: req)
        let input = try req.content.decode(ChangePasswordRequest.self)
        let user = try req.auth.require(User.self)

        guard try await req.password.async.verify(input.currentPassword, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Current password is incorrect.")
        }

        user.passwordHash = try await req.password.async.hash(input.newPassword)
        user.updatedAt = Date()
        try await user.save(on: req.db)

        // Changing a password invalidates all existing sessions for this account.
        try await UserToken.query(on: req.db).filter(\.$user.$id == user.requireID()).delete()
        return .noContent
    }
}
