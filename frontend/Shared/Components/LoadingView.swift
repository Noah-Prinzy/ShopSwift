import SwiftUI

struct LoadingView: View {
    var message = "Loading..."

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
            Text(message)
                .foregroundStyle(.secondary)
        }
    }
}
