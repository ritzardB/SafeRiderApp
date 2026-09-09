//
//  TrackingView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 09/09/2026.
//

import SwiftUI
import MapKit

struct TrackingView: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            if let driver = dataManager.currentDriver {
                let students = dataManager.students(for: driver)

                if students.isEmpty {
                    ContentUnavailableView(
                        "No Assigned Students",
                        systemImage: "car.fill",
                        description: Text(
                            "No students are currently assigned "
                            + "to this driver."
                        )
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(students) { student in
                                TrackingStudentCard(student: student)
                            }
                        }
                        .padding()
                    }
                }
            } else {
                ContentUnavailableView(
                    "Driver Profile Not Found",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(
                        "No driver profile is linked to this account."
                    )
                )
            }
        }
        .navigationTitle("Tracking")
    }
}

// MARK: - Student Tracking Card

struct TrackingStudentCard: View {
    @EnvironmentObject private var dataManager: DataManager

    let student: Student

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // MARK: Student Header

            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundStyle(SafeRiderTheme.blue)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(SafeRiderTheme.blue.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(student.name)
                        .font(.headline)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                    Text(
                        "Grade \(student.grade) • "
                        + "Section \(student.section)"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }

                Spacer()
            }

            Divider()

            // MARK: Morning Pickup

            trackingSection(
                title: "Morning Pickup",
                icon: "sunrise.fill",
                time: "07:15 AM",
                location: studentPickupLocation,
                statusTitle: "Driver On The Way"
            )

            // MARK: School

            locationRow(
                title: "School",
                location: student.school
            )

            // MARK: Afternoon Pickup

            trackingSection(
                title: "Afternoon Pickup",
                icon: "sunset.fill",
                time: "02:30 PM",
                location: student.school,
                statusTitle: "Driver On The Way"
            )

            // MARK: Home Drop-off

            locationRow(
                title: "Home Drop-off",
                location: homeDropOffLocation
            )

            Divider()

            // MARK: Navigation

            HStack(spacing: 12) {
                mapButton(
                    title: "Home",
                    icon: "house.fill",
                    destination: homeDropOffLocation
                )

                mapButton(
                    title: "School",
                    icon: "building.2.fill",
                    destination: student.school
                )
            }
        }
        .padding(16)
        .background(SafeRiderTheme.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            y: 3
        )
    }

    // MARK: - Tracking Section

    @ViewBuilder
    private func trackingSection(
        title: String,
        icon: String,
        time: String,
        location: String,
        statusTitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Spacer()

                Text(time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )
            }

            locationRow(
                title: "Pickup Location",
                location: location
            )

            Button {
                updateRideStatus(statusTitle)
            } label: {
                Label(
                    statusTitle,
                    systemImage: "car.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SafeRiderTheme.orange)
        }
    }

    // MARK: - Location Row

    @ViewBuilder
    private func locationRow(
        title: String,
        location: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(
                    SafeRiderTheme.orange
                )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                Text(
                    location.isEmpty
                        ? "Location not set"
                        : location
                )
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
            }

            Spacer()
        }
    }

    // MARK: - Map Button

    @ViewBuilder
    private func mapButton(
        title: String,
        icon: String,
        destination: String
    ) -> some View {
        Button {
            openMaps(destination: destination)
        } label: {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(SafeRiderTheme.blue)
    }

    // MARK: - Helpers

    private var studentPickupLocation: String {
        "Home"
    }

    private var homeDropOffLocation: String {
        "Home"
    }

    private func updateRideStatus(_ status: String) {
        print(
            "Tracking status '\(status)' for \(student.name)"
        )

        // Ride status integration will be connected
        // to the Firebase ride workflow next.
    }

    private func openMaps(destination: String) {
        guard !destination.isEmpty else {
            return
        }

        let encoded = destination
            .addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ) ?? ""

        guard let url = URL(
            string: "http://maps.apple.com/?address=\(encoded)"
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }
}
