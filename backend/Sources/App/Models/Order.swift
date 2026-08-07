import Fluent
import Vapor

/// Checkout snapshot. Order items copy the product name/price so old orders stay historically accurate.
final class Order: Model, @unchecked Sendable {
    static let schema = "orders"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "total")
    var total: Double

    @Field(key: "status")
    var status: String

    @Field(key: "created_at")
    var createdAt: Date

    init() {}

    init(id: UUID? = nil, userID: UUID, total: Double, status: String = "confirmed") {
        self.id = id
        self.$user.id = userID
        self.total = total
        self.status = status
        self.createdAt = Date()
    }
}

final class OrderItem: Model, @unchecked Sendable {
    static let schema = "order_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: Order

    @Parent(key: "product_id")
    var product: Product

    @Field(key: "product_name")
    var productName: String

    @Field(key: "unit_price")
    var unitPrice: Double

    @Field(key: "quantity")
    var quantity: Int

    init() {}

    init(orderID: UUID, productID: UUID, productName: String, unitPrice: Double, quantity: Int) {
        self.$order.id = orderID
        self.$product.id = productID
        self.productName = productName
        self.unitPrice = unitPrice
        self.quantity = quantity
    }
}

struct OrderItemResponse: Content {
    let productID: UUID
    let productName: String
    let unitPrice: Double
    let quantity: Int
    let lineTotal: Double
}

struct OrderResponse: Content {
    let id: UUID
    let status: String
    let total: Double
    let createdAt: Date
    let items: [OrderItemResponse]
}
