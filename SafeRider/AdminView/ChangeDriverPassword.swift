//
//  ChangeDriverPassword.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 20/09/2026.
//

import SwiftUI
import FirebaseAuth

struct ChangeDriverPasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    @State private var isChangingPassword = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {
                Section("Current Password") {
                    SecureField(
                        "Enter current password",
                        text: $currentPassword
                    )
                }

                Section("New Password") {
                    SecureField(
                        "Enter new password",
                        text: $newPassword
                    )

                    SecureField(
                        "Confirm new password",
                        text: $confirmPassword
                    )
                }

                Section {
                    Text(
                        "Use a strong password that you haven't used before."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        HStack {
                            Spacer()

                            if isChangingPassword {
                                ProgressView("Updating...")
                            } else {
                                Label(
                                    "Change Password",
                                    systemImage: "lock.fill"
                                )
                                .fontWeight(.semibold)
                            }

                            Spacer()
                        }
                    }
                    .disabled(
                        isChangingPassword ||
                        currentPassword.isEmpty ||
                        newPassword.isEmpty ||
                        confirmPassword.isEmpty
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Password Updated",
            isPresented: $showingSuccess
        ) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(
                "Your password has been changed successfully."
            )
        }
        .alert(
            "Unable to Change Password",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: {
                    if !$0 {
                        errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Change Password

    @MainActor
    private func changePassword() async {
        guard !isChangingPassword else {
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "New passwords do not match."
            return
        }

        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }

        guard currentPassword != newPassword else {
            errorMessage = "New password must differ from current password."
            return
        }

        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "Unable to identify your account."
            return
        }

        isChangingPassword = true
        defer {
            isChangingPassword = false
        }

        do {
            // Reauthenticate before changing the password.
            let credential = EmailAuthProvider.credential(
                withEmail: email,
                password: currentPassword
            )

            try await user.reauthenticate(with: credential)

            // Update Firebase Authentication password.
            try await user.updatePassword(to: newPassword)

            currentPassword = ""
            newPassword = ""
            confirmPassword = ""

            showingSuccess = true

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
