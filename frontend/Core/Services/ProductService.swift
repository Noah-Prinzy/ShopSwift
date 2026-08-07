import Foundation

struct ProductService {
    let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func products(category: String? = nil, search: String? = nil) async throws -> [Product] {
        var queryItems: [URLQueryItem] = []
        if let category, !category.isEmpty { queryItems.append(URLQueryItem(name: "category", value: category)) }
        if let search, !search.isEmpty { queryItems.append(URLQueryItem(name: "q", value: search)) }
        return try await apiClient.send(
            APIEndpoint(path: "/api/v1/products", queryItems: queryItems),
            as: [Product].self,
            token: nil
        )
    }

    func categories() async throws -> [String] {
        try await apiClient.send(APIEndpoint(path: "/api/v1/categories"), as: [String].self, token: nil)
    }
}
