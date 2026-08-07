import Vapor

/// Small diagnostic middleware that prints method + path without logging passwords or request bodies.
struct RequestLoggingMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        request.logger.info("\(request.method) \(request.url.path)")
        return try await next.respond(to: request)
    }
}
