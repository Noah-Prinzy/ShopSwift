import SwiftUI

// Product list UI: loads categories and products from the API and supports search.
// Short notes:
// - `task` loads data on view appearance; `onChange`/`onSubmit` trigger reloading.
struct ProductListView: View {
    @State private var products: [Product] = []
    @State private var categories: [String] = []
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var errorMessage: String?
    private let service = ProductService()

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag("All")
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
            }

            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else {
                ForEach(products) { product in
                    NavigationLink(value: product) { ProductRow(product: product) }
                }
            }
        }
        .navigationTitle("Shop")
        .searchable(text: $searchText, prompt: "Search products")
        .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
        .task { await loadCategories(); await loadProducts() }
        .onChange(of: selectedCategory) { _, _ in Task { await loadProducts() } }
        .onSubmit(of: .search) { Task { await loadProducts() } }
    }

    @MainActor
    // Load available categories from the backend for the category picker.
    private func loadCategories() async {
        do { categories = try await service.categories() } catch { }
    }

    @MainActor
    // Load products with optional category and search filters. Sets `errorMessage` on failure.
    private func loadProducts() async {
        errorMessage = nil
        do {
            products = try await service.products(
                category: selectedCategory == "All" ? nil : selectedCategory,
                search: searchText.isEmpty ? nil : searchText
            )
        } catch { errorMessage = error.localizedDescription }
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            AsyncImage(url: product.imageURL.flatMap(URL.init(string:))) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(.quaternary)
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(product.name).font(.headline)
                Text(product.category).font(.caption).foregroundStyle(.secondary)
                Text(product.price, format: .currency(code: "USD"))
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
