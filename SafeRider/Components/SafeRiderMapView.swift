//
//  SafeRiderMapView.swift
//  SafeRider
//
//  Reusable MapKit component for SafeRider
//

import SwiftUI
import MapKit

struct SafeRiderMapView: View {
    let homeAddress: String
    let schoolAddress: String
    let driverLatitude: Double?
    let driverLongitude: Double?

    @State private var homeCoordinate: CLLocationCoordinate2D?
    @State private var schoolCoordinate: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var isLoading = true
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var routeError: String?

    var body: some View {
        ZStack {
            Map(position: $mapPosition) {
                // MARK: - Home

                if let homeCoordinate {
                    Annotation(
                        "Home",
                        coordinate: homeCoordinate
                    ) {
                        mapMarker(
                            icon: "house.fill",
                            color: SafeRiderTheme.orange
                        )
                    }
                }

                // MARK: - School

                if let schoolCoordinate {
                    Annotation(
                        "School",
                        coordinate: schoolCoordinate
                    ) {
                        mapMarker(
                            icon: "building.2.fill",
                            color: SafeRiderTheme.blue
                        )
                    }
                }

                // MARK: - Driver

                if let driverCoordinate {
                    Annotation(
                        "Driver",
                        coordinate: driverCoordinate
                    ) {
                        mapMarker(
                            icon: "car.fill",
                            color: SafeRiderTheme.success
                        )
                    }
                }

                // MARK: - Actual Driving Route

                if let route {
                    MapPolyline(route)
                        .stroke(
                            SafeRiderTheme.orange,
                            lineWidth: 5
                        )
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )

            // MARK: - Loading

            if isLoading {
                ProgressView("Loading route...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )
            }

            // MARK: - Error

            if let routeError {
                VStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.title2)

                    Text(routeError)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
                .padding()
            }

            // MARK: - No Locations

            if !isLoading &&
                homeCoordinate == nil &&
                schoolCoordinate == nil {

                VStack(spacing: 8) {
                    Image(systemName: "mappin.slash")
                        .font(.title2)

                    Text("Location information unavailable")
                        .font(.caption)
                }
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
                .padding()
                .background(.regularMaterial)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .task {
            await loadMap()
        }
        .onChange(of: driverLatitude) {
            updateMapPosition()
        }
        .onChange(of: driverLongitude) {
            updateMapPosition()
        }
    }

    // MARK: - Driver Coordinate

    private var driverCoordinate:
        CLLocationCoordinate2D? {

        guard
            let latitude = driverLatitude,
            let longitude = driverLongitude
        else {
            return nil
        }

        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    // MARK: - Map Marker

    @ViewBuilder
    private func mapMarker(
        icon: String,
        color: Color
    ) -> some View {

        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 42, height: 42)
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 4,
                    y: 2
                )

            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
        }
    }

    // MARK: - Load Map

    private func loadMap() async {
        isLoading = true
        routeError = nil

        let home = await geocode(
            address: homeAddress
        )

        let school = await geocode(
            address: schoolAddress
        )

        await MainActor.run {
            homeCoordinate = home
            schoolCoordinate = school
        }

        // Need both locations for a driving route.
        guard
            let home,
            let school
        else {
            await MainActor.run {
                isLoading = false
                routeError = "Unable to determine the home or school location."
            }
            return
        }

        await calculateDrivingRoute(
            from: home,
            to: school
        )

        await MainActor.run {
            isLoading = false
        }
    }

    // MARK: - Geocoding

    private func geocode(
        address: String
    ) async -> CLLocationCoordinate2D? {

        guard !address.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return nil
        }

        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(
                address
            )

            return placemarks.first?.location?.coordinate
        } catch {
            print(
                "❌ Geocoding failed for \(address): \(error.localizedDescription)"
            )

            return nil
        }
    }

    // MARK: - Driving Route

    private func calculateDrivingRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async {

        let sourcePlacemark = MKPlacemark(
            coordinate: source
        )

        let destinationPlacemark = MKPlacemark(
            coordinate: destination
        )

        let request = MKDirections.Request()

        request.source = MKMapItem(
            placemark: sourcePlacemark
        )

        request.destination = MKMapItem(
            placemark: destinationPlacemark
        )

        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(
            request: request
        )

        do {
            let response = try await directions.calculate()

            guard let calculatedRoute = response.routes.first else {
                await MainActor.run {
                    routeError = "No driving route was found."
                }
                return
            }

            await MainActor.run {
                route = calculatedRoute

                let rect = calculatedRoute.polyline.boundingMapRect

                mapPosition = .rect(
                    rect.insetBy(
                        dx: -rect.width * 0.15,
                        dy: -rect.height * 0.15
                    )
                )
            }

            print("🗺️ Driving route calculated:")

            print(
                "📏 Distance: \(calculatedRoute.distance / 1000) km"
            )

            print(
                "⏱️ ETA: \(calculatedRoute.expectedTravelTime / 60) minutes"
            )

        } catch {
            print(
                "❌ MKDirections failed: \(error.localizedDescription)"
            )

            await MainActor.run {
                routeError =
                    "Unable to calculate the driving route."
            }
        }
    }

    // MARK: - Driver Map Update

    private func updateMapPosition() {
        guard
            let driverCoordinate
        else {
            return
        }

        if let route {
            let routeRect = route.polyline.boundingMapRect

            let driverPoint = MKMapPoint(
                driverCoordinate
            )

            let combinedRect = routeRect.union(
                MKMapRect(
                    x: driverPoint.x - 500,
                    y: driverPoint.y - 500,
                    width: 1000,
                    height: 1000
                )
            )

            mapPosition = .rect(
                combinedRect.insetBy(
                    dx: -combinedRect.width * 0.10,
                    dy: -combinedRect.height * 0.10
                )
            )
        } else {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: driverCoordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.03,
                        longitudeDelta: 0.03
                    )
                )
            )
        }
    }
}

#Preview {
    SafeRiderMapView(
        homeAddress:
            "Villa 48 Sultan Bin Ghanoum Al Hameli St., Abu Dhabi, UAE",
        schoolAddress:
            "Electra Street, Abu Dhabi, UAE",
        driverLatitude: nil,
        driverLongitude: nil
    )
    .padding()
    .background(
        SafeRiderTheme.orangeTint
    )
}
