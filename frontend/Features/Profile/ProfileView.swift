import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @State private var username = ""
    @State private var email = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var message: String?

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                Button("Save Profile") { Task { await saveProfile() } }
            }

            Section("Change Password") {
                SecureField("Current password", text: $currentPassword)
                SecureField("New password (8+ characters)", text: $newPassword)
                Button("Change Password") { Task { await changePassword() } }
                    .disabled(currentPassword.isEmpty || newPassword.count < 8)
            }

            if let message { Text(message).foregroundStyle(.secondary) }

            Section {
                Button("Sign Out", role: .destructive) { Task { await session.logout() } }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            username = session.user?.username ?? ""
            email = session.user?.email ?? ""
        }
    }

    @MainActor private func saveProfile() async {
        do {
            try await session.updateProfile(username: username, email: email)
            message = "Profile updated."
        } catch { message = error.localizedDescription }
    }

    @MainActor private func changePassword() async {
        do {
            try await session.changePassword(current: currentPassword, new: newPassword)
            message = "Password changed. Please sign in again."
        } catch { message = error.localizedDescription }
    }
}
