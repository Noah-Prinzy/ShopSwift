import Fluent
import FluentPostgresDriver
import Foundation
import Vapor

/// Configures the PostgreSQL connection used by Fluent at runtime.
/// Flyway owns table creation; Fluent is intentionally used only for queries and persistence.
///
/// Notes:
/// - The app prefers `DATABASE_URL` for hosted environments.
/// - Render supplies an internal PostgreSQL URL for same-region private-network traffic.
/// - `DATABASE_TLS_MODE=disable` is used only for that private Render connection.
/// - Local development falls back to individual `DATABASE_*` env vars.
enum DatabaseConfiguration {
    static func configure(_ app: Application) throws {
        if let databaseURL = Environment.get("DATABASE_URL"), !databaseURL.isEmpty {
            if Environment.get("DATABASE_TLS_MODE")?.lowercased() == "disable" {
                try configurePrivateDatabaseURL(databaseURL, on: app)
            } else {
                try app.databases.use(.postgres(url: databaseURL), as: .psql)
                app.logger.info("PostgreSQL configured from DATABASE_URL")
            }
            return
        }

        let host = Environment.get("DATABASE_HOST") ?? "localhost"
        let port = Int(Environment.get("DATABASE_PORT") ?? "5432") ?? 5432
        let database = Environment.get("DATABASE_NAME") ?? "shopswift_db"
        let username = Environment.get("DATABASE_USERNAME") ?? "shopswift_user"
        let password = Environment.get("DATABASE_PASSWORD") ?? "change_me"

        app.databases.use(
            .postgres(
                configuration: .init(
                    hostname: host,
                    port: port,
                    username: username,
                    password: password,
                    database: database,
                    tls: .disable
                )
            ),
            as: .psql
        )

        app.logger.info("PostgreSQL configured for \(host):\(port)/\(database)")
    }

    /// Render's Blueprint `connectionString` points to PostgreSQL over Render's
    /// same-region private network. Flyway can consume that URL directly, while
    /// PostgresNIO is configured explicitly here so it does not attempt public
    /// certificate verification for the private hostname.
    private static func configurePrivateDatabaseURL(_ databaseURL: String, on app: Application) throws {
        guard let components = URLComponents(string: databaseURL),
              let host = components.host,
              !host.isEmpty else {
            throw Abort(.internalServerError, reason: "Invalid hosted database configuration.")
        }

        let port = components.port ?? 5432
        let databaseFromURL = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let database = Environment.get("DATABASE_NAME")
            ?? (databaseFromURL.isEmpty ? "shopswift_db" : databaseFromURL)
        let username = Environment.get("DATABASE_USERNAME") ?? "shopswift_user"
        let password = Environment.get("DATABASE_PASSWORD") ?? "change_me"

        app.databases.use(
            .postgres(
                configuration: .init(
                    hostname: host,
                    port: port,
                    username: username,
                    password: password,
                    database: database,
                    tls: .disable
                )
            ),
            as: .psql
        )

        app.logger.info("PostgreSQL configured from private DATABASE_URL with TLS disabled")
    }
}
