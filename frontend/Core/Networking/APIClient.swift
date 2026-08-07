import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type, token: String?) async throws -> T
    func send(_ endpoint: APIEndpoint, token: String?) async throws
}

/// Shared URLSession client used by every frontend service.
final class APIClient: APIClientProtocol {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type, token: String? = nil) async throws -> T {
        let data = try await perform(endpoint, token: token)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    func send(_ endpoint: APIEndpoint, token: String? = nil) async throws {
        _ = try await perform(endpoint, token: token)
    }

    private func perform(_ endpoint: APIEndpoint, token: String?) async throws -> Data {
        let request = try endpoint.makeRequest(token: token)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data).reason)
                ?? "The server returned HTTP status \(httpResponse.statusCode)."
            throw APIError.httpStatus(httpResponse.statusCode, message)
        }
        return data
    }
}
