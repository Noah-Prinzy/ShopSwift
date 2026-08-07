import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var session: AppSession
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Create your account") {
                TextField("Unique username", text: $username)
                    .textInputAutocapitalization(.never)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password (8+ characters)", text: $password)
                SecureField("Confirm password", text: $confirmPassword)
            }

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }

            Button(isLoading ? "Creating..." : "Create Account") {
                Task { await createAccount() }
            }
            .disabled(isLoading || username.isEmpty || email.isEmpty || password.isEmpty)
        }
        .navigationTitle("Sign Up")
    }

    @MainActor
    private func createAccount() async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard Validation.isValidEmail(email) else {
            errorMessage = "Enter a valid email address."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await session.signup(username: username, email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
