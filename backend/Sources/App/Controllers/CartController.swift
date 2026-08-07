import Fluent
import Vapor

/// Protected shopping-cart endpoints.
///
/// Short notes:
/// - Routes are authenticated via `UserToken` so these handlers operate on the current user.
/// - `addItem` validates inventory and merges quantities when the same product exists.
struct CartController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let cart = routes
            .grouped("api", "v1", "cart")
            .grouped(UserToken.authenticator())

        cart.get(use: show)
        cart.post("items", use: addItem)
        cart.patch("items", ":cartItemID", use: updateItem)
        cart.delete("items", ":cartItemID", use: removeItem)
        cart.delete(use: clear)
    }

    // GET /api/v1/cart
    // Returns the current user's cart built from `CartItem` rows joined with products.
    func show(req: Request) async throws -> CartResponse {
        let user = try req.auth.require(User.self)
        return try await buildCart(userID: user.requireID(), on: req.db)
    }

    // POST /api/v1/cart/items
    // Adds a product to the user's cart or increments an existing cart item; enforces stock limits.
    func addItem(req: Request) async throws -> CartResponse {
        try AddCartItemRequest.validate(content: req)
        let input = try req.content.decode(AddCartItemRequest.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let product = try await Product.find(input.productID, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found.")
        }

        let existing = try await CartItem.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$product.$id == input.productID)
            .first()

        let requestedQuantity = (existing?.quantity ?? 0) + input.quantity
        guard requestedQuantity <= product.stock else {
            throw Abort(.badRequest, reason: "Only \(product.stock) units are currently in stock.")
        }

        if let existing {
            existing.quantity = requestedQuantity
            existing.updatedAt = Date()
            try await existing.save(on: req.db)
        } else {
            let item = CartItem(userID: userID, productID: input.productID, quantity: input.quantity)
            try await item.save(on: req.db)
        }

        return try await buildCart(userID: userID, on: req.db)
    }

    // PATCH /api/v1/cart/items/:cartItemID
    // Updates the quantity for a cart item after validating stock and ownership.
    func updateItem(req: Request) async throws -> CartResponse {
        try UpdateCartItemRequest.validate(content: req)
        let input = try req.content.decode(UpdateCartItemRequest.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()

        guard let itemID = req.parameters.get("cartItemID", as: UUID.self),
              let item = try await CartItem.query(on: req.db)
                .filter(\.$id == itemID)
                .filter(\.$user.$id == userID)
                .with(\.$product)
                .first() else {
            throw Abort(.notFound, reason: "Cart item not found.")
        }

        guard input.quantity <= item.product.stock else {
            throw Abort(.badRequest, reason: "Only \(item.product.stock) units are currently in stock.")
        }

        item.quantity = input.quantity
        item.updatedAt = Date()
        try await item.save(on: req.db)
        return try await buildCart(userID: userID, on: req.db)
    }

    // DELETE /api/v1/cart/items/:cartItemID
    // Removes a specific cart item for the authenticated user.
    func removeItem(req: Request) async throws -> CartResponse {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        guard let itemID = req.parameters.get("cartItemID", as: UUID.self),
              let item = try await CartItem.query(on: req.db)
                .filter(\.$id == itemID)
                .filter(\.$user.$id == userID)
                .first() else {
            throw Abort(.notFound, reason: "Cart item not found.")
        }
        try await item.delete(on: req.db)
        return try await buildCart(userID: userID, on: req.db)
    }

    // DELETE /api/v1/cart
    // Clears all items for the authenticated user's cart.
    func clear(req: Request) async throws -> HTTPStatus {
        let userID = try req.auth.require(User.self).requireID()
        try await CartItem.query(on: req.db).filter(\.$user.$id == userID).delete()
        return .noContent
    }

    // Helper: build a `CartResponse` by loading CartItem rows, their products, and computing totals.
    private func buildCart(userID: UUID, on database: Database) async throws -> CartResponse {
        let rows = try await CartItem.query(on: database)
            .filter(\.$user.$id == userID)
            .with(\.$product)
            .sort(\.$createdAt)
            .all()

        let items = try rows.map { row in
            let product = try ProductResponse(product: row.product)
            return CartItemResponse(
                id: try row.requireID(),
                product: product,
                quantity: row.quantity,
                lineTotal: product.price * Double(row.quantity)
            )
        }
        return CartResponse(items: items, total: items.reduce(0) { $0 + $1.lineTotal })
    }
}
