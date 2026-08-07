import SwiftUI

struct HomeView: View {
    @State private var products: [Product] = []
    @State private var errorMessage: String?
    private let service = ProductService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SMART TECH · SIMPLER SHOPPING")
                        .font(.caption.bold())
                        .tracking(1.1)
                        .foregroundStyle(AppColors.accent)
                    Text("Upgrade your everyday.")
                        .font(AppTypography.title)
                    Text("Thoughtfully selected electronics for work, play and everything between.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.large)
                .background(
                    LinearGradient(
                        colors: [AppColors.accentSoft, AppColors.accent.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                if let errorMessage {
                    ErrorView(message: errorMessage) { Task { await load() } }
                } else if products.isEmpty {
                    LoadingView(message: "Loading products...")
                } else {
                    Text("Featured products")
                        .font(AppTypography.heading)
                    ForEach(products.prefix(4)) { product in
                        NavigationLink(value: product) {
                            ProductRow(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("ShopSwift")
        .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        .task { if products.isEmpty { await load() } }
    }

    @MainActor
    private func load() async {
        errorMessage = nil
        do { products = try await service.products() }
        catch { errorMessage = error.localizedDescription }
    }
}
