//
//  ServiceAreaInputView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 21/09/2026.
//

import SwiftUI

struct ServiceAreaInputView: View {

    @Binding var serviceArea: String

    @StateObject private var locationManager = LocationManager()
    @State private var isDetectingLocation = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Service Area")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SafeRiderTheme.primaryText)

            Text(
                "Enter the city or municipality where you provide "
                + "your driving services."
            )
            .font(.footnote)
            .foregroundStyle(SafeRiderTheme.secondaryText)

            // MARK: - City Input

            TextField(
                "Enter city or municipality",
                text: $serviceArea
            )
            .textContentType(.addressCity)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(12)
            .background(SafeRiderTheme.background)
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
            .accessibilityLabel("Service area city")

            // MARK: - Detect Location Button

            Button {
                Task {
                    await detectLocation()
                }
            } label: {
                HStack(spacing: 8) {
                    if isDetectingLocation {
                        ProgressView()
                            .tint(SafeRiderTheme.orange)
                    } else {
                        Image(systemName: "location.circle")
                    }

                    Text(
                        isDetectingLocation
                            ? "Detecting Location..."
                            : "Detect My Current Location"
                    )
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(SafeRiderTheme.orange)
            }
            .buttonStyle(.plain)
            .disabled(isDetectingLocation)

            // MARK: - Location Error

            if let errorMessage = locationManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            // MARK: - Location Confirmation

            if !serviceArea.isEmpty {
                Label(
                    "Service area: \(serviceArea)",
                    systemImage: "mappin.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(SafeRiderTheme.secondaryText)
            }
        }
        .padding(14)
        .background(SafeRiderTheme.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
    }

    // MARK: - Location Detection

    @MainActor
    private func detectLocation() async {
        isDetectingLocation = true
        defer { isDetectingLocation = false }

        await locationManager.detectCurrentCity()

        if !locationManager.detectedCity.isEmpty {
            serviceArea = locationManager.detectedCity
        }
    }
}

// MARK: - Preview

#Preview {
    ServiceAreaInputView(
        serviceArea: .constant("")
    )
    .padding()
}
