//
//  ParentDriverInfoView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 15/09/2026.
//

import SwiftUI

struct ParentDriverInfoView: View {

    @EnvironmentObject private var dataManager: DataManager

    private var parent: Parent? {
        dataManager.currentParent
    }

    private var assignedChildren: [Student] {
        guard let parent else { return [] }

        return dataManager.students(for: parent).filter {
            $0.driverId != nil
        }
    }

    private var driver: Driver? {
        guard let driverID = assignedChildren.first?.driverId else {
            return nil
        }

        return dataManager.drivers.first {
            $0.id == driverID
        }
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                driverHeader

                if let driver {
                    driverDetails(driver)

                    assignedChildrenSection(
                        children: assignedChildren
                    )
                } else {
                    driverUnavailable
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()
        )
        .navigationTitle("Driver Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Driver Header

    private var driverHeader: some View {

        VStack(spacing: 14) {

            if let driver {
                ProfileAvatarView(
                    name: driver.name,
                    photoURL: driver.photoURL,
                    size: 100
                )
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
            }

            Text(driver?.name.isEmpty == false
                 ? driver?.name ?? "Driver"
                 : "Assigned Driver"
            )
            .font(.title2.weight(.bold))
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )

            if let driver,
               !driver.vehicleType.isEmpty {

                Text(driver.vehicleType)
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
            }

            Text("Your SafeRider Driver")
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Driver Details

    private func driverDetails(
        _ driver: Driver
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text("Driver Details")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            detailRow(
                icon: "person.fill",
                title: "Name",
                value: driver.name.isEmpty
                    ? "Not provided"
                    : driver.name
            )

            detailRow(
                icon: "car.fill",
                title: "Vehicle",
                value: driver.vehicleType.isEmpty
                    ? "Not provided"
                    : driver.vehicleType
            )

            detailRow(
                icon: "number",
                title: "Vehicle Number",
                value: driver.vehicleNumber.isEmpty
                    ? "Not provided"
                    : driver.vehicleNumber
            )

            detailRow(
                icon: "doc.text.fill",
                title: "License Number",
                value: driver.licenseNumber.isEmpty
                    ? "Not provided"
                    : driver.licenseNumber
            )

            if !driver.phoneNumber.isEmpty {
                contactDriverSection(driver)
            }

            if !driver.email.isEmpty {
                detailRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: driver.email
                )
            }
        }
        .padding(20)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }
    
    // MARK: - Contact Driver

    private func contactDriverSection(
        _ driver: Driver
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Contact Driver")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            Text(driver.phoneNumber)
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            HStack(spacing: 12) {

                contactButton(
                    title: "Call",
                    icon: "phone.fill",
                    action: {
                        callDriver(
                            phoneNumber: driver.phoneNumber
                        )
                    }
                )

                contactButton(
                    title: "Message",
                    icon: "message.fill",
                    action: {
                        messageDriver(
                            phoneNumber: driver.phoneNumber
                        )
                    }
                )

                contactButton(
                    title: "WhatsApp",
                    icon: "message.circle.fill",
                    action: {
                        whatsappDriver(
                            phoneNumber: driver.phoneNumber
                        )
                    }
                )
            }
        }
        .padding(20)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }
    
    private func contactButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            VStack(spacing: 8) {

                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
            .background(
                SafeRiderTheme.orangeTint
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func messageDriver(
        phoneNumber: String
    ) {

        let cleanedNumber = phoneNumber
            .filter {
                $0.isNumber || $0 == "+"
            }

        guard let url = URL(
            string: "sms:\(cleanedNumber)"
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }
    
    private func whatsappDriver(
        phoneNumber: String
    ) {

        let cleanedNumber = phoneNumber
            .filter {
                $0.isNumber
            }

        guard let url = URL(
            string: "whatsapp://send?phone=\(cleanedNumber)"
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }

    // MARK: - Assigned Children

    private func assignedChildrenSection(
        children: [Student]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Text("Your Children")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            ForEach(children) { child in

                HStack(spacing: 12) {

                    ProfileAvatarView(
                        name: child.name,
                        photoURL: child.photoURL,
                        size: 50
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(child.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        Text(
                            "Grade \(child.grade) • \(child.school)"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                }
                .padding(14)
                .background(
                    SafeRiderTheme.surface
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
            }
        }
    }

    // MARK: - Driver Unavailable

    private var driverUnavailable: some View {

        VStack(spacing: 12) {

            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            Text("Driver information unavailable")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            Text(
                "No driver is currently assigned to your children."
            )
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(
                SafeRiderTheme.secondaryText
            )
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
    }

    // MARK: - Detail Row

    private func detailRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(
                    SafeRiderTheme.blue
                )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                Text(value)
                    .font(.body.weight(.medium))
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
            }

            Spacer()
        }
    }

    // MARK: - Phone

    private func callDriver(
        phoneNumber: String
    ) {

        let cleanedNumber = phoneNumber
            .filter {
                $0.isNumber || $0 == "+"
            }

        guard let url = URL(
            string: "tel://\(cleanedNumber)"
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }
}
