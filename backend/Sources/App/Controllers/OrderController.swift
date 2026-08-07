import Fluent
import Vapor

/// Minimal checkout/history support so Phase 1 demonstrates the complete shopping loop.
///
/// Notes:
/// - `checkout` runs inside a DB transaction to create an `Order`, move items, and adjust stock atomically.
struct OrderController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let orders = routes
            .grouped("api", "v1", "orders")
            .grouped(UserToken.authenticator())

        orders.get(use: index)
        orders.post("checkout", use: checkout)
    }

    // GET /api/v1/orders
    // Returns the authenticated user's orders, newest first, converted to API DTOs.
    func index(req: Request) async throws -> [OrderResponse] {
        let userID = try req.auth.require(User.self).requireID()
        let orders = try await Order.query(on: req.db)
            .filter(\.$user.$id == userID)
            .sort(\.$createdAt, .descending)
            .all()

        var responses: [OrderResponse] = []
        for order in orders {
            responses.append(try await makeResponse(order: order, on: req.db))
        }
        return responses
    }

    // POST /api/v1/orders/checkout
    // Performs prototype checkout: validates cart, decrements product stock, creates order and items.
    func checkout(req: Request) async throws -> OrderResponse {
        let userID = try req.auth.require(User.self).requireID()

        return try await req.db.transaction { database in
            let cartItems = try await CartItem.query(on: database)
                .filter(\.$user.$id == userID)
                .with(\.$product)
                .all()

            guard !cartItems.isEmpty else {
                throw Abort(.badRequest, reason: "Your cart is empty.")
            }

            // Validate stock for all items before mutating any data.
            for item in cartItems {
                guard item.quantity <= item.product.stock else {
                    throw Abort(.badRequest, reason: "Not enough stock for \(item.product.name).")
                }
            }

            let total = cartItems.reduce(0.0) { $0 + ($1.product.price * Double($1.quantity)) }
            let order = Order(userID: userID, total: total)
            try await order.save(on: database)
            let orderID = try order.requireID()

            for item in cartItems {
                let orderItem = OrderItem(
                    orderID: orderID,
                    productID: try item.product.requireID(),
                    productName: item.product.name,
                    unitPrice: item.product.price,
                    quantity: item.quantity
                )
                try await orderItem.save(on: database)

                // Reduce stock as part of the same database transaction to keep inventory consistent.
                item.product.stock -= item.quantity
                try await item.product.save(on: database)
                try await item.delete(on: database)
            }

            return try await makeResponse(order: order, on: database)
        }
    }

    private func makeResponse(order: Order, on database: Database) async throws -> OrderResponse {
        let orderID = try order.requireID()
        let items = try await OrderItem.query(on: database)
            .filter(\.$order.$id == orderID)
            .all()
            .map {
                OrderItemResponse(
                    productID: $0.$product.id,
                    productName: $0.productName,
                    unitPrice: $0.unitPrice,
                    quantity: $0.quantity,
                    lineTotal: $0.unitPrice * Double($0.quantity)
                )
            }

        return OrderResponse(
            id: orderID,
            status: order.status,
            total: order.total,
            createdAt: order.createdAt,
            items: items
        )
    }
}
