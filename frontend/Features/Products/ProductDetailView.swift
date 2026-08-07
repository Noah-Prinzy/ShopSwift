import SwiftUI

// Detailed product presentation and Add-to-Cart action.
// Notes:
// - Uses `AppSession` for auth token access when calling cart APIs.
struct ProductDetailView: View {
    @EnvironmentObject private var session: AppSession
    let product: Product
    @State private var statusMessage: String?
    @State private var isAdding = false
    private let cartService = CartService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AsyncImage(url: product.imageURL.flatMap(URL.init(string:))) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Rectangle().fill(.quaternary).frame(height: 260)
                }
                .frame(maxWidth: .infinity)

                Text(product.name).font(AppTypography.heading)
                Text(product.price, format: .currency(code: "USD")).font(.title3.bold())
                Text(product.description).foregroundStyle(.secondary)
                Text(product.stock > 0 ? "In stock: \(product.stock)" : "Out of stock")
                    .font(.caption)

                PrimaryButton(title: isAdding ? "Adding..." : "Add to Cart") {
                    Task { await addToCart() }
                }
                .disabled(isAdding || product.stock == 0)

                if let statusMessage { Text(statusMessage).font(.caption) }
            }
            .padding()
        }
        .navigationTitle(product.category)
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    // Adds the product to the server-side cart using the session token.
    private func addToCart() async {
        guard let token = session.token else { return }
        isAdding = true
        defer { isAdding = false }
        do {
            _ = try await cartService.add(productID: product.id, token: token)
            statusMessage = "Added to cart."
        } catch { statusMessage = error.localizedDescription }
    }
}
