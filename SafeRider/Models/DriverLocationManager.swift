import Foundation
import CoreLocation

@MainActor
final class DriverLocationManager: NSObject, ObservableObject {

    @Published private(set) var authorizationStatus:
        CLAuthorizationStatus = .notDetermined

    @Published private(set) var currentLocation: CLLocation?

    @Published private(set) var isTracking = false

    private let locationManager = CLLocationManager()

    private var shouldStartAfterAuthorization = false

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = false
    }

    // MARK: - Permission

    func requestPermission() {

        guard CLLocationManager.locationServicesEnabled() else {
            print("⚠️ Location services are disabled.")
            return
        }

        switch authorizationStatus {

        case .authorizedWhenInUse,
             .authorizedAlways:

            startUpdatingLocation()

        case .notDetermined:

            shouldStartAfterAuthorization = true

            print(
                "📍 Requesting location permission..."
            )

            locationManager.requestWhenInUseAuthorization()

        case .denied,
             .restricted:

            print(
                "⚠️ Location permission is denied or restricted."
            )

        @unknown default:

            print(
                "⚠️ Unknown location authorization status."
            )
        }
    }

    // MARK: - Tracking

    func startTracking() {

        guard CLLocationManager.locationServicesEnabled() else {
            print("⚠️ Location services are disabled.")
            return
        }

        switch authorizationStatus {

        case .authorizedWhenInUse,
             .authorizedAlways:

            startUpdatingLocation()

        case .notDetermined:

            shouldStartAfterAuthorization = true

            print(
                "📍 Location permission has not been determined."
            )

            requestPermission()

        case .denied,
             .restricted:

            print(
                "⚠️ Location permission is denied or restricted."
            )

        @unknown default:

            print(
                "⚠️ Unknown location authorization status."
            )
        }
    }

    // MARK: - Stop Tracking

    func stopTracking() {

        locationManager.stopUpdatingLocation()

        isTracking = false

        print("🛑 Location tracking stopped.")
    }

    // MARK: - Location Updates

    private func startUpdatingLocation() {

        locationManager.startUpdatingLocation()

        isTracking = true

        print("📍 Location tracking started.")
    }

    // MARK: - Authorization

    private func handleAuthorizationChange(
        _ status: CLAuthorizationStatus
    ) {

        authorizationStatus = status

        print(
            "📍 Location authorization changed:",
            status.rawValue
        )

        switch status {

        case .authorizedWhenInUse,
             .authorizedAlways:

            if shouldStartAfterAuthorization {

                shouldStartAfterAuthorization = false

                startUpdatingLocation()
            }

        case .denied,
             .restricted:

            shouldStartAfterAuthorization = false

            isTracking = false

            locationManager.stopUpdatingLocation()

            print(
                "⚠️ Location permission unavailable."
            )

        case .notDetermined:

            print(
                "📍 Location authorization is not determined."
            )

        @unknown default:

            print(
                "⚠️ Unknown location authorization status."
            )
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension DriverLocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else {
            return
        }

        guard location.horizontalAccuracy >= 0 else {
            return
        }

        Task { @MainActor in

            self.currentLocation = location

            print(
                "📍 GPS: \(location.coordinate.latitude), " +
                "\(location.coordinate.longitude)"
            )
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {

        print(
            "❌ Driver location error: \(error.localizedDescription)"
        )
    }

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {

        let status = manager.authorizationStatus

        Task { @MainActor in
            self.handleAuthorizationChange(status)
        }
    }
}
