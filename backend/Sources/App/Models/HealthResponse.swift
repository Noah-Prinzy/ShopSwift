import Vapor

struct HealthResponse: Content {
    let status: String
    let message: String
}
