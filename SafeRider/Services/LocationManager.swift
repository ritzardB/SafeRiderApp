//
//  LocationManager.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 21/09/2026.
//

import Foundation
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {

    @Published var detectedCity: String = ""
    @Published var errorMessage: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private var locationContinuation:
        CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Request Current Location

    func detectCurrentCity() async {
        errorMessage = nil

        do {
            let location = try await requestLocation()

            let placemarks = try await geocoder.reverseGeocodeLocation(
                location
            )

            guard let placemark = placemarks.first else {
                throw LocationError.cityNotFound
            }

            guard let city = placemark.locality
                ?? placemark.subAdministrativeArea else {
                throw LocationError.cityNotFound
            }

            detectedCity = city

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Location Request

    private func requestLocation() async throws -> CLLocation {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            throw LocationError.permissionDenied

        default:
            break
        }

        return try await withCheckedThrowingContinuation {
            continuation in

            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        if manager.authorizationStatus == .denied
            || manager.authorizationStatus == .restricted {
            locationContinuation?.resume(
                throwing: LocationError.permissionDenied
            )
            locationContinuation = nil
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            locationContinuation?.resume(
                throwing: LocationError.locationUnavailable
            )
            locationContinuation = nil
            return
        }

        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

// MARK: - Location Errors

enum LocationError: LocalizedError {

    case permissionDenied
    case locationUnavailable
    case cityNotFound

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission is required to detect your city."

        case .locationUnavailable:
            return "Unable to retrieve your current location."

        case .cityNotFound:
            return "Unable to determine your city. Please enter it manually."
        }
    }
}
