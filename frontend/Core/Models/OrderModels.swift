import Foundation

struct OrderItem: Codable, Identifiable {
    var id: UUID { productID }
    let productID: UUID
    let productName: String
    let unitPrice: Double
    let quantity: Int
    let lineTotal: Double
}

struct Order: Codable, Identifiable {
    let id: UUID
    let status: String
    let total: Double
    let createdAt: Date
    let items: [OrderItem]
}
