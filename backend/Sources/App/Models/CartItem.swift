import Fluent
import Vapor

/// One product/quantity row in a shopper's cart.
final class CartItem: Model, @unchecked Sendable {
    static let schema = "cart_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "product_id")
    var product: Product

    @Field(key: "quantity")
    var quantity: Int

    @Field(key: "created_at")
    var createdAt: Date

    @Field(key: "updated_at")
    var updatedAt: Date

    init() {}

    init(id: UUID? = nil, userID: UUID, productID: UUID, quantity: Int) {
        self.id = id
        self.$user.id = userID
        self.$product.id = productID
        self.quantity = quantity
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct CartItemResponse: Content {
    let id: UUID
    let product: ProductResponse
    let quantity: Int
    let lineTotal: Double
}

struct CartResponse: Content {
    let items: [CartItemResponse]
    let total: Double
}
