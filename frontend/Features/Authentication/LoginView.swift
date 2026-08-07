import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Account") {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
            }

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }

            Button(isLoading ? "Signing In..." : "Sign In") {
                Task { await signIn() }
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
        }
        .navigationTitle("Sign In")
    }

    @MainActor
    private func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await session.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
