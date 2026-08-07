import Fluent
import Vapor

/// Public catalog endpoints. REST is ideal here because these are request/response resources.
///
/// Short notes:
/// - `boot` wires HTTP routes to handlers.
/// - `index` supports optional `category` and `q` (search) query params.
/// - `show` returns a single product by UUID.
struct ProductController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let products = routes.grouped("api", "v1", "products")
        products.get(use: index)
        products.get(":productID", use: show)

        routes.get("api", "v1", "categories", use: categories)
    }

    // GET /api/v1/products
    // Returns the product list; applies category filtering and a simple name search.
    func index(req: Request) async throws -> [ProductResponse] {
        var query = Product.query(on: req.db)

        if let category: String = req.query["category"], !category.isEmpty {
            query = query.filter(\.$category == category)
        }

        // Use Fluent's `~~` operator to perform a basic name search (case-insensitive contains).
        if let rawSearch: String = req.query["q"],
           !rawSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let search = rawSearch.trimmingCharacters(in: .whitespacesAndNewlines)
            query = query.filter(\.$name ~~ search)
        }

        let products = try await query.sort(\.$name).all()
        return try products.map(ProductResponse.init(product:))
    }

    // GET /api/v1/products/:productID
    // Loads a product by UUID and returns a response DTO suitable for the API.
    func show(req: Request) async throws -> ProductResponse {
        guard let id = req.parameters.get("productID", as: UUID.self),
              let product = try await Product.find(id, on: req.db) else {
            throw Abort(.notFound, reason: "Product not found.")
        }
        return try ProductResponse(product: product)
    }

    // GET /api/v1/categories
    // Returns deduplicated, sorted categories derived from products in the DB.
    func categories(req: Request) async throws -> [String] {
        // Keeping categories database-driven avoids a separate categories table for Phase 1.
        let products = try await Product.query(on: req.db).sort(\.$category).all()
        return Array(Set(products.map(\.category))).sorted()
    }
}
