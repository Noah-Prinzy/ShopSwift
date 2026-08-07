import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Double
    let category: String
    let imageURL: String?
    let stock: Int
}
