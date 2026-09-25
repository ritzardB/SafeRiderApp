//
//  DriverNotificationManager.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 24/09/2026.
//

import Foundation
import UserNotifications

@MainActor
final class DriverNotificationManager: ObservableObject {

    @Published var isAuthorized = false

    init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current()
            .getNotificationSettings { [weak self] settings in

                Task { @MainActor in
                    self?.isAuthorized =
                        settings.authorizationStatus == .authorized ||
                        settings.authorizationStatus == .provisional
                }
            }
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(
                    options: [.alert, .sound, .badge]
                )

            isAuthorized = granted

        } catch {
            print(
                "Notification permission error: \(error.localizedDescription)"
            )
        }
    }
    
    func sendRideNotification(
        title: String,
        body: String,
        rideID: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        content.userInfo = [
            "type": "ride_update",
            "rideID": rideID
        ]

        let request = UNNotificationRequest(
            identifier: "ride_update_\(rideID)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print(
                    "Ride notification error: \(error.localizedDescription)"
                )
            }
        }
    }
    
}
