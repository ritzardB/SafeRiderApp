//
//  PaymentFrequency.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 23/09/2026.
//

import Foundation

enum PaymentFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case oneTime = "One-Time"

    var id: String {
        rawValue
    }
}
