import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .parent
    @State private var errorMessage = ""
    @State private var isRegistering = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }

                Section("Account Type") {
                    Picker("Role", selection: $role) {
                        Text("Parent").tag(UserRole.parent)
                        Text("Driver").tag(UserRole.driver)
                    }
                    .pickerStyle(.segmented)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundStyle(.red)
                }

                Button(isRegistering ? "Creating Account…" : "Create Account") {
                    Task { await register() }
                }
                .disabled(email.isEmpty || password.isEmpty || isRegistering)
            }
            .navigationTitle("New Registration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func register() async {
        isRegistering = true
        defer { isRegistering = false }
        let result = await authManager.register(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            role: role
        )

        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
