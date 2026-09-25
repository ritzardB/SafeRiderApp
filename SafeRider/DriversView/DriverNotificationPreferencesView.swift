import SwiftUI
import UserNotifications

struct DriverNotificationPreferencesView: View {

    @AppStorage("driverRideNotifications")
    private var rideNotifications = true

    @AppStorage("driverPaymentNotifications")
    private var paymentNotifications = true

    @AppStorage("driverScheduleNotifications")
    private var scheduleNotifications = true

    @AppStorage("driverAnnouncementNotifications")
    private var announcementNotifications = true

    @StateObject private var notificationManager =
        DriverNotificationManager()

    var body: some View {

        Form {

            // MARK: - Notification Permission

            Section("Notification Permission") {

                HStack {
                    Label(
                        "Push Notifications",
                        systemImage: "bell.badge"
                    )

                    Spacer()

                    Text(
                        notificationManager.isAuthorized
                        ? "Enabled"
                        : "Not Enabled"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        notificationManager.isAuthorized
                        ? .green
                        : .secondary
                    )
                }

                if !notificationManager.isAuthorized {
                    Button {
                        Task {
                            await notificationManager.requestPermission()
                        }
                    } label: {
                        Label(
                            "Enable Notifications",
                            systemImage: "bell"
                        )
                    }
                }
            }

            // MARK: - Notification Preferences

            Section {

                Toggle(
                    "Ride Updates",
                    isOn: $rideNotifications
                )

                Toggle(
                    "Payment Updates",
                    isOn: $paymentNotifications
                )

                Toggle(
                    "Schedule Changes",
                    isOn: $scheduleNotifications
                )

                Toggle(
                    "Announcements",
                    isOn: $announcementNotifications
                )

            } header: {
                Text("Notification Preferences")
            } footer: {
                Text(
                    "Choose which SafeRider updates you want to receive."
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(SafeRiderTheme.orangeTint)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
}
