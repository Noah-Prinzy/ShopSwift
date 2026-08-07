import Fluent
import Vapor

/// Registration and login REST endpoints.
///
/// Notes:
/// - `signup` and `login` return a short `AuthResponse` with a bearer token for API calls.
/// - Password hashing/verification is intentionally asynchronous to avoid blocking the event loop.
struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("api", "v1", "auth")
        auth.post("signup", use: signup)
        auth.post("login", use: login)

        let protected = auth.grouped(UserToken.authenticator())
        protected.post("logout", use: logout)
    }

    // POST /api/v1/auth/signup
    // Validates input, creates a new `User`, stores a hashed password and returns an auth token.
    func signup(req: Request) async throws -> AuthResponse {
        try SignUpRequest.validate(content: req)
        let input = try req.content.decode(SignUpRequest.self)
        let email = input.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let username = input.username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard try await User.query(on: req.db).filter(\.$email == email).first() == nil else {
            throw Abort(.conflict, reason: "An account with that email already exists.")
        }
        guard try await User.query(on: req.db).filter(\.$username == username).first() == nil else {
            throw Abort(.conflict, reason: "That username is already taken.")
        }

        // Password hashing is intentionally asynchronous so CPU-heavy bcrypt work does not block the event loop.
        let passwordHash = try await req.password.async.hash(input.password)
        let user = User(username: username, email: email, passwordHash: passwordHash)
        try await user.save(on: req.db)

        let token = try UserToken.generate(for: user)
        try await token.save(on: req.db)
        return AuthResponse(token: token.value, user: try UserResponse(user: user))
    }

    // POST /api/v1/auth/login
    // Validates credentials and returns a bearer token when successful.
    func login(req: Request) async throws -> AuthResponse {
        try LoginRequest.validate(content: req)
        let input = try req.content.decode(LoginRequest.self)
        let email = input.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        guard try await req.password.async.verify(input.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        let token = try UserToken.generate(for: user)
        try await token.save(on: req.db)
        return AuthResponse(token: token.value, user: try UserResponse(user: user))
    }

    // POST /api/v1/auth/logout
    // Invalidates the current bearer token by deleting it from the DB.
    func logout(req: Request) async throws -> HTTPStatus {
        _ = try req.auth.require(User.self)
        guard let bearer = req.headers.bearerAuthorization else {
            throw Abort(.unauthorized)
        }
        try await UserToken.query(on: req.db).filter(\.$value == bearer.token).delete()
        return .noContent
    }
}
