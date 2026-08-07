import Vapor

/// Registers all Phase 1 REST resources in one predictable /api/v1 namespace.
public func routes(_ app: Application) throws {
    app.get("health") { _ in
        HealthResponse(status: "ok", message: "ShopSwift API is running")
    }

    try app.register(collection: AuthController())
    try app.register(collection: ProfileController())
    try app.register(collection: ProductController())
    try app.register(collection: CartController())
    try app.register(collection: OrderController())

    // The browser prototype is served by Vapor itself, avoiding CORS during local demos.
    app.get { req -> Response in
        req.fileio.streamFile(at: app.directory.publicDirectory + "index.html")
    }
}
