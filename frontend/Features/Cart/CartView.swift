import SwiftUI

// Cart UI: shows items, allows quantity updates/removals and prototype checkout.
// Notes:
// - All cart API calls require the user's bearer token from `AppSession`.
struct CartView: View {
    @EnvironmentObject private var session: AppSession
    @State private var cart = ShoppingCart.empty
    @State private var message: String?
    @State private var isCheckingOut = false
    private let cartService = CartService()
    private let orderService = OrderService()

    var body: some View {
        List {
            if cart.items.isEmpty {
                ContentUnavailableView("Your cart is empty", systemImage: "cart", description: Text("Add a product from the Shop tab."))
            } else {
                ForEach(cart.items) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.product.name).font(.headline)
                        Text("Quantity: \(item.quantity)")
                        Text(item.lineTotal, format: .currency(code: "USD"))
                            .fontWeight(.semibold)
                        HStack {
                            Button("−") { Task { await setQuantity(item, item.quantity - 1) } }
                                .disabled(item.quantity <= 1)
                            Button("+") { Task { await setQuantity(item, item.quantity + 1) } }
                                .disabled(item.quantity >= item.product.stock)
                            Spacer()
                            Button("Remove", role: .destructive) { Task { await remove(item) } }
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }

                Section("Summary") {
                    HStack {
                        Text("Total")
                        Spacer()
                        Text(cart.total, format: .currency(code: "USD")).fontWeight(.bold)
                    }
                    Button(isCheckingOut ? "Processing..." : "Prototype Checkout") {
                        Task { await checkout() }
                    }
                    .disabled(isCheckingOut)
                }
            }

            if let message { Text(message).foregroundStyle(.secondary) }
        }
        .navigationTitle("Cart")
        .task { await load() }
        .refreshable { await load() }
    }

    @MainActor private func load() async {
        // Fetch the current shopping cart for the authenticated user.
        guard let token = session.token else { return }
        do { cart = try await cartService.cart(token: token) }
        catch { message = error.localizedDescription }
    }

    @MainActor private func setQuantity(_ item: CartItem, _ quantity: Int) async {
        // Update a cart item's quantity on the backend then refresh local cart state.
        guard let token = session.token, quantity > 0 else { return }
        do { cart = try await cartService.update(itemID: item.id, quantity: quantity, token: token) }
        catch { message = error.localizedDescription }
    }

    @MainActor private func remove(_ item: CartItem) async {
        guard let token = session.token else { return }
        do { cart = try await cartService.remove(itemID: item.id, token: token) }
        catch { message = error.localizedDescription }
    }

    @MainActor private func checkout() async {
        // Perform prototype checkout; on success clear the UI cart and show a confirmation.
        guard let token = session.token else { return }
        isCheckingOut = true
        defer { isCheckingOut = false }
        do {
            let order = try await orderService.checkout(token: token)
            cart = .empty
            message = "Order \(order.id.uuidString.prefix(8)) confirmed."
        } catch { message = error.localizedDescription }
    }
}
