// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShopSwift",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Vapor provides the HTTP server, routing, validation, middleware, and password hashing.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.100.0"),
        // Fluent is Vapor's ORM. The PostgreSQL driver connects Fluent models to PostgreSQL.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.9.0")
    ],
    targets: [
        // App contains all reusable backend code (models, controllers, services, routes, database setup).
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver")
            ],
            path: "Sources/App"
        ),
        // Run is deliberately separate: it is only responsible for starting the server.
        .executableTarget(
            name: "Run",
            dependencies: [.target(name: "App")],
            path: "Sources/Run"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor")
            ],
            path: "Tests/AppTests"
        )
    ]
)
