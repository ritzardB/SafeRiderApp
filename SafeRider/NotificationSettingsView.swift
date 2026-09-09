//
//  NotificationSettingsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 09/09/2026.
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notifications.rideUpdates")
    private var rideUpdates = true

    @AppStorage("notifications.paymentUpdates")
    private var paymentUpdates = true

    @AppStorage("notifications.driverMessages")
    private var driverMessages = true

    @AppStorage("notifications.general")
    private var generalNotifications = true

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {
                Section {
                    Toggle(isOn: $rideUpdates) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Ride Updates")
                                    .foregroundStyle(SafeRiderTheme.primaryText)

                                Text("Pickup, school arrival, return, and home arrival alerts")
                                    .font(.caption)
                                    .foregroundStyle(SafeRiderTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "car.fill")
                                .foregroundStyle(SafeRiderTheme.orange)
                        }
                    }

                    Toggle(isOn: $paymentUpdates) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Payment Updates")
                                    .foregroundStyle(SafeRiderTheme.primaryText)

                                Text("Payment confirmations and payment-related alerts")
                                    .font(.caption)
                                    .foregroundStyle(SafeRiderTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(SafeRiderTheme.orange)
                        }
                    }

                    Toggle(isOn: $driverMessages) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Driver Messages")
                                    .foregroundStyle(SafeRiderTheme.primaryText)

                                Text("Messages and communication from your driver")
                                    .font(.caption)
                                    .foregroundStyle(SafeRiderTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "message.fill")
                                .foregroundStyle(SafeRiderTheme.orange)
                        }
                    }

                    Toggle(isOn: $generalNotifications) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("General Notifications")
                                    .foregroundStyle(SafeRiderTheme.primaryText)

                                Text("Important SafeRider announcements and updates")
                                    .font(.caption)
                                    .foregroundStyle(SafeRiderTheme.secondaryText)
                            }
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(SafeRiderTheme.orange)
                        }
                    }
                } header: {
                    Text("Notification Preferences")
                } footer: {
                    Text("These preferences control which SafeRider notifications you receive.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
