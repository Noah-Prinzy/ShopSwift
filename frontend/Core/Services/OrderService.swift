import Foundation

struct OrderService {
    let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func checkout(token: String) async throws -> Order {
        try await apiClient.send(
            APIEndpoint(path: "/api/v1/orders/checkout", method: .post),
            as: Order.self,
            token: token
        )
    }

    func orders(token: String) async throws -> [Order] {
        try await apiClient.send(APIEndpoint(path: "/api/v1/orders"), as: [Order].self, token: token)
    }
}
