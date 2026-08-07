import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)

            Text(message)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button("Try Again", action: retryAction)
            }
        }
        .padding()
    }
}
