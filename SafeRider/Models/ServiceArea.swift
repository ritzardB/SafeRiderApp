//
//  ServiceArea.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 21/09/2026.
//

import Foundation

struct ServiceArea: Identifiable, Codable, Hashable {
    // MARK: - Properties

    var id: String
    var countryCode: String
    var countryName: String
    var region: String
    var city: String
    var district: String?

    // MARK: - Initializer

    init(
        id: String = UUID().uuidString,
        countryCode: String,
        countryName: String,
        region: String,
        city: String,
        district: String? = nil
    ) {
        self.id = id
        self.countryCode = countryCode
        self.countryName = countryName
        self.region = region
        self.city = city
        self.district = district
    }

    // MARK: - Display Name

    var displayName: String {
        let location = [district, city, region]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return "\(location), \(countryName)"
    }
}
