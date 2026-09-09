//
//  NotificationManager.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 09/09/2026.
//

import Foundation
import FirebaseFirestore

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Parent Ride Notifications
    
    func sendParentRideNotification(
        parentId: UUID,
        studentId: UUID,
        title: String,
        message: String
    ) async {
        guard rideNotificationsEnabled(for: parentId) else {
            return
        }
        
        let notificationId = UUID()
        
        let data: [String: Any] = [
            "id": notificationId.uuidString,
            "parentId": parentId.uuidString,
            "studentId": studentId.uuidString,
            "type": "rideUpdate",
            "title": title,
            "message": message,
            "isRead": false,
            "createdAt": Timestamp(date: Date())
        ]
        
        do {
            try await db
                .collection("notifications")
                .document(notificationId.uuidString)
                .setData(data)
        } catch {
            print("Notification error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Preference
    
    private func rideNotificationsEnabled(for parentId: UUID) -> Bool {
        UserDefaults.standard.object(forKey: "notifications.rideUpdates") == nil
        ? true
        : UserDefaults.standard.bool(forKey: "notifications.rideUpdates")
    }
    
}

extension NotificationManager {

    func notifyRideStatusChange(
        status: RideStatus,
        parentId: UUID,
        studentId: UUID,
        studentName: String
    ) async {

        let title: String
        let message: String

        switch status {
        case .scheduled:
            title = "Ride Scheduled"
            message = "\(studentName)'s ride has been scheduled."

        case .driverEnRoute:
            title = "Driver On The Way"
            message = "Your driver is on the way to pick up \(studentName)."

        case .pickedUp:
            title = "Child Picked Up"
            message = "\(studentName) has been picked up."

        case .droppedAtSchool:
            title = "Arrived at School"
            message = "\(studentName) has arrived safely at school."

        case .returning:
            title = "Returning Home"
            message = "The driver is returning \(studentName) home."

        case .arrivedHome:
            title = "Arrived Home"
            message = "\(studentName) has arrived home safely."

        case .cancelled:
            title = "Ride Cancelled"
            message = "\(studentName)'s ride has been cancelled."
        }

        await sendParentRideNotification(
            parentId: parentId,
            studentId: studentId,
            title: title,
            message: message
        )
    }
}
