import Foundation

struct CartItem: Codable, Identifiable {
    let id: UUID
    let product: Product
    let quantity: Int
    let lineTotal: Double
}

struct ShoppingCart: Codable {
    let items: [CartItem]
    let total: Double

    static let empty = ShoppingCart(items: [], total: 0)
}
