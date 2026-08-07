import XCTVapor
@testable import App

final class AppTests: XCTestCase {
    func testHealthRoute() async throws {
        let app = try await Application.make(.testing)
        defer { Task { try await app.asyncShutdown() } }

        // The health route itself does not touch PostgreSQL, so this test only registers routes.
        try routes(app)

        try await app.testing().test(.GET, "health") { response in
            XCTAssertEqual(response.status, .ok)
            XCTAssertTrue(response.body.string.contains("ShopSwift API is running"))
        }
    }
}
