//
//  ChangePasswordView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 09/09/2026.
//

import SwiftUI
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var isChangingPassword = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private var passwordsMatch: Bool {
        !newPassword.isEmpty
        && newPassword == confirmPassword
    }

    private var isValid: Bool {
        newPassword.count >= 6
        && passwordsMatch
        && !currentPassword.isEmpty
        && !isChangingPassword
    }

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {
                Section("Current Password") {
                    SecureField(
                        "Current Password",
                        text: $currentPassword
                    )
                }

                Section("New Password") {
                    SecureField(
                        "New Password",
                        text: $newPassword
                    )

                    SecureField(
                        "Confirm New Password",
                        text: $confirmPassword
                    )

                    if !newPassword.isEmpty
                        && newPassword.count < 6 {
                        Text(
                            "Password must be at least 6 characters."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.danger
                        )
                    }

                    if !confirmPassword.isEmpty
                        && !passwordsMatch {
                        Text("Passwords do not match.")
                            .font(.caption)
                            .foregroundStyle(
                                SafeRiderTheme.danger
                            )
                    }
                }

                Section {
                    Button {
                        changePassword()
                    } label: {
                        HStack {
                            Spacer()

                            if isChangingPassword {
                                ProgressView()
                            } else {
                                Label(
                                    "Change Password",
                                    systemImage: "key.fill"
                                )
                                .fontWeight(.semibold)
                            }

                            Spacer()
                        }
                    }
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )
                    .disabled(!isValid)
                }

                if let successMessage {
                    Section {
                        Label(
                            successMessage,
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Change Password")
        .alert(
            "Password Change Failed",
            isPresented: Binding(
                get: {
                    errorMessage != nil
                },
                set: { value in
                    if !value {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                errorMessage ?? ""
            )
        }
    }

    private func changePassword() {
        guard
            let user = Auth.auth().currentUser
        else {
            errorMessage =
                "No authenticated user was found."
            return
        }

        guard passwordsMatch else {
            errorMessage =
                "The new passwords do not match."
            return
        }

        guard newPassword.count >= 6 else {
            errorMessage =
                "Password must be at least 6 characters."
            return
        }

        isChangingPassword = true
        successMessage = nil

        Task {
            do {
                guard let email = user.email else {
                    throw PasswordError.emailUnavailable
                }

                let credential =
                    EmailAuthProvider.credential(
                        withEmail: email,
                        password: currentPassword
                    )

                try await user.reauthenticate(
                    with: credential
                )

                try await user.updatePassword(
                    to: newPassword
                )

                await MainActor.run {
                    isChangingPassword = false
                    successMessage =
                        "Your password has been changed successfully."

                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                }

            } catch {
                await MainActor.run {
                    isChangingPassword = false
                    errorMessage =
                        error.localizedDescription
                }
            }
        }
    }
}

private enum PasswordError: LocalizedError {
    case emailUnavailable

    var errorDescription: String? {
        switch self {
        case .emailUnavailable:
            return "The Firebase account email is unavailable."
        }
    }
}
