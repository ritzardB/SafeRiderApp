//
//  PaymentArrangement.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 23/09/2026.
//

import Foundation

struct PaymentArrangement: Identifiable, Codable {

    var id: UUID = UUID()

    var parentId: UUID
    var studentId: UUID

    var paymentFrequency: PaymentFrequency
    var amount: Double

    var dueDay: Int?
    var dueWeekday: Int?

    var nextDueDate: Date

    var isActive: Bool = true

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
