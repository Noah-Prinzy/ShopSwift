import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if session.isRestoring {
                LoadingView(message: "Restoring your account...")
            } else if session.isAuthenticated {
                ShopTabView()
            } else {
                NavigationStack { AuthenticationView() }
            }
        }
        .tint(AppColors.accent)
        .task { await session.restore() }
    }
}

private struct ShopTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
            NavigationStack { ProductListView() }
                .tabItem { Label("Shop", systemImage: "bag") }
            NavigationStack { CartView() }
                .tabItem { Label("Cart", systemImage: "cart") }
            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
