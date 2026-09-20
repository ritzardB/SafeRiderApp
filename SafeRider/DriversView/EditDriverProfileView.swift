//
//  EditDriverProfileView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 20/09/2026.
//

import SwiftUI

struct EditDriverProfileView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let driver: Driver

    @State private var name: String
    @State private var phoneNumber: String

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    init(driver: Driver) {
        self.driver = driver

        _name = State(initialValue: driver.name)
        _phoneNumber = State(initialValue: driver.phoneNumber)
    }

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {
                // MARK: - Personal Information

                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)

                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                // MARK: - Account Email

                Section("Account Email") {
                    LabeledContent(
                        "Email Address",
                        value: driver.email
                    )

                    Text(
                        "To change your account email, use the account security settings."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }

                // MARK: - Save

                Section {
                    Button {
                        Task {
                            saveProfile()
                        }
                    } label: {
                        HStack {
                            Spacer()

                            if isSaving {
                                ProgressView("Saving...")
                            } else {
                                Label(
                                    "Save Changes",
                                    systemImage: "checkmark.circle"
                                )
                                .fontWeight(.semibold)
                            }

                            Spacer()
                        }
                    }
                    .disabled(
                        isSaving ||
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        phoneNumber.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Profile Updated", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been updated successfully.")
        }
        .alert(
            "Unable to Update Profile",
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

    // MARK: - Save Profile

    @MainActor
    private func saveProfile() {
        guard !isSaving else {
            return
        }

        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedPhone = phoneNumber.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty,
              !trimmedPhone.isEmpty else {
            errorMessage = "Name and phone number are required."
            return
        }

        isSaving = true
        defer {
            isSaving = false
        }

        var updatedDriver = driver
        updatedDriver.name = trimmedName
        updatedDriver.phoneNumber = trimmedPhone

        dataManager.updateDriver(updatedDriver)

        showingSuccess = true
    }
}
