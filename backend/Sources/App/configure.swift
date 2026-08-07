import Fluent
import Vapor

public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = Environment.get("HOST") ?? "127.0.0.1"
    app.http.server.configuration.port = Int(Environment.get("PORT") ?? "8080") ?? 8080

    app.passwords.use(.bcrypt)
    try DatabaseConfiguration.configure(app)

    // Browser assets under backend/Public are exposed by Vapor.
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Development-friendly CORS. Restrict origins before public production deployment.
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    app.middleware.use(RequestLoggingMiddleware())
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    try routes(app)
}
