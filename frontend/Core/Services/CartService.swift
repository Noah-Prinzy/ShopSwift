import Foundation

private struct AddCartPayload: Encodable {
    let productID: UUID
    let quantity: Int
}

private struct UpdateCartPayload: Encodable {
    let quantity: Int
}

struct CartService {
    let apiClient: APIClientProtocol
    private let encoder = JSONEncoder()

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func cart(token: String) async throws -> ShoppingCart {
        try await apiClient.send(APIEndpoint(path: "/api/v1/cart"), as: ShoppingCart.self, token: token)
    }

    func add(productID: UUID, quantity: Int = 1, token: String) async throws -> ShoppingCart {
        let body = try encoder.encode(AddCartPayload(productID: productID, quantity: quantity))
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/cart/items", method: .post, body: body),
            as: ShoppingCart.self,
            token: token
        )
    }

    func update(itemID: UUID, quantity: Int, token: String) async throws -> ShoppingCart {
        let body = try encoder.encode(UpdateCartPayload(quantity: quantity))
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/cart/items/\(itemID.uuidString)", method: .patch, body: body),
            as: ShoppingCart.self,
            token: token
        )
    }

    func remove(itemID: UUID, token: String) async throws -> ShoppingCart {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/cart/items/\(itemID.uuidString)", method: .delete),
            as: ShoppingCart.self,
            token: token
        )
    }
}
