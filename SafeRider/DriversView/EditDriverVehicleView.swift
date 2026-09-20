//
//  EditDriverVehicleView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 20/09/2026.
//

import SwiftUI

struct EditDriverVehicleView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let driver: Driver

    @State private var vehicleType: String
    @State private var vehicleNumber: String
    @State private var licenseNumber: String

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false

    init(driver: Driver) {
        self.driver = driver

        _vehicleType = State(
            initialValue: driver.vehicleType
        )

        _vehicleNumber = State(
            initialValue: driver.vehicleNumber
        )

        _licenseNumber = State(
            initialValue: driver.licenseNumber
        )
    }

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {
                // MARK: - Vehicle Information

                Section("Vehicle Information") {
                    TextField(
                        "Vehicle Type",
                        text: $vehicleType
                    )
                    .textInputAutocapitalization(.words)

                    TextField(
                        "Vehicle Registration Number",
                        text: $vehicleNumber
                    )
                    .textInputAutocapitalization(.characters)

                    TextField(
                        "Driver's License Number",
                        text: $licenseNumber
                    )
                    .textInputAutocapitalization(.characters)
                }

                // MARK: - Save Changes

                Section {
                    Button {
                        saveVehicleInformation()
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
                        vehicleType.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        vehicleNumber.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        licenseNumber.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Vehicle Information")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "Vehicle Information Updated",
            isPresented: $showingSuccess
        ) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(
                "Your vehicle information has been updated successfully."
            )
        }
        .alert(
            "Unable to Update Vehicle",
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

    // MARK: - Save Vehicle Information

    @MainActor
    private func saveVehicleInformation() {
        guard !isSaving else {
            return
        }

        let trimmedVehicleType = vehicleType.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedVehicleNumber = vehicleNumber.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let trimmedLicenseNumber = licenseNumber.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedVehicleType.isEmpty,
              !trimmedVehicleNumber.isEmpty,
              !trimmedLicenseNumber.isEmpty else {
            errorMessage = "Please complete all vehicle information."
            return
        }

        isSaving = true
        defer {
            isSaving = false
        }

        var updatedDriver = driver

        updatedDriver.vehicleType = trimmedVehicleType
        updatedDriver.vehicleNumber = trimmedVehicleNumber
        updatedDriver.licenseNumber = trimmedLicenseNumber

        dataManager.updateDriver(updatedDriver)

        showingSuccess = true
    }
}
