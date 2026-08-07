import Fluent
import FluentPostgresDriver
import Vapor

/// Configures the PostgreSQL connection used by Fluent at runtime.
/// Flyway owns table creation; Fluent is intentionally used only for queries and persistence.
///
/// Notes:
/// - The app will prefer `DATABASE_URL` for hosted environments.
/// - Local development falls back to individual `DATABASE_*` env vars.
enum DatabaseConfiguration {
    static func configure(_ app: Application) throws {
        if let databaseURL = Environment.get("DATABASE_URL"), !databaseURL.isEmpty {
            try app.databases.use(.postgres(url: databaseURL), as: .psql)
            app.logger.info("PostgreSQL configured from DATABASE_URL")
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
}
