//
//  PublicDriverListing.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 21/09/2026.
//

import Foundation

struct PublicDriverListing: Identifiable, Codable {

    var id: String
    var name: String
    var photoURL: String?
    var serviceArea: String
    var vehicleType: String
}
