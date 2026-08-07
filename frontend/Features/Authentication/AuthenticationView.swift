import SwiftUI

/// Small entry screen that keeps Login and Sign Up easy to discover.
///
/// Notes:
/// - Visual styling is driven by `AppColors` and `AppTypography` in `Shared/Theme`.
struct AuthenticationView: View {
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 104, height: 104)
                Image(systemName: "bag.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text("ShopSwift")
                .font(AppTypography.title)
            Text("Modern electronics, powered by Swift and Vapor.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink("Sign In") { LoginView() }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)
                .controlSize(.large)
            NavigationLink("Create Account") { SignUpView() }
                .buttonStyle(.bordered)
                .tint(AppColors.accent)
                .controlSize(.large)
            Spacer()
        }
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [AppColors.background, AppColors.accentSoft.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}
