import Fluent
import Vapor

/// A product that can be browsed and placed in a cart.
final class Product: Model, Content, @unchecked Sendable {
    static let schema = "products"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String

    @Field(key: "price")
    var price: Double

    @Field(key: "category")
    var category: String

    @OptionalField(key: "image_url")
    var imageURL: String?

    @Field(key: "stock")
    var stock: Int

    @Field(key: "created_at")
    var createdAt: Date

    init() {}
}

struct ProductResponse: Content {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let category: String
    let imageURL: String?
    let stock: Int

    init(product: Product) throws {
        id = try product.requireID()
        name = product.name
        description = product.description
        price = product.price
        category = product.category
        imageURL = product.imageURL
        stock = product.stock
    }
}
