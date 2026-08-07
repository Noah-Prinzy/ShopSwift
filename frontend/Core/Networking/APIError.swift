import Foundation

struct APIErrorBody: Decodable {
    let reason: String?
    let error: Bool?
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int, String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API URL is invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .httpStatus(_, let message):
            return message
        case .decodingFailed:
            return "The server response could not be decoded."
        }
    }
}
