import SwiftUI

struct AdminLoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isSigningIn = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Administrator") {
                    TextField("Admin Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundStyle(.red)
                }

                Button(isSigningIn ? "Signing In…" : "Admin Login") {
                    Task { await authenticateAdmin() }
                }
                .disabled(email.isEmpty || password.isEmpty || isSigningIn)
            }
            .navigationTitle("Admin Login")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func authenticateAdmin() async {
        isSigningIn = true
        defer { isSigningIn = false }

        let result = await authManager.login(email: email, password: password)
        switch result {
        case .success:
            if authManager.userRole == .admin {
                dismiss()
            } else {
                authManager.logout()
                errorMessage = "This account is not authorized for administrator access."
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
