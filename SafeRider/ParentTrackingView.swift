//
//  ParentTrackingView.swift
//  SafeRider
//

import SwiftUI

struct ParentTrackingView: View {

    @EnvironmentObject private var dataManager: DataManager

    // When supplied, only this child is displayed.
    // When nil, all children belonging to the current parent are displayed.
    let selectedStudent: Student?

    init(student: Student? = nil) {
        self.selectedStudent = student
    }

    private var displayedStudents: [Student] {
        guard let parent = dataManager.currentParent else {
            return []
        }

        let parentStudents = dataManager.students(for: parent)

        guard let selectedStudent else {
            return parentStudents
        }

        return parentStudents.filter {
            $0.id == selectedStudent.id
        }
    }

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            if displayedStudents.isEmpty {
                ContentUnavailableView(
                    "No Student Found",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(
                        selectedStudent == nil
                            ? "No children are currently linked to your account."
                            : "The selected child could not be found in your account."
                    )
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(displayedStudents) { student in
                            studentTrackingCard(student)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(
            selectedStudent == nil
                ? "Tracking"
                : "\(selectedStudent!.name) Tracking"
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Student Tracking Card

    @ViewBuilder
    private func studentTrackingCard(
        _ student: Student
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            // MARK: Student Header

            HStack(spacing: 12) {

                ProfileAvatarView(
                    name: student.name,
                    photoURL: student.photoURL,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 4) {

                    Text(student.name)
                        .font(.title3.weight(.bold))
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

            // MARK: Driver

            if let driverId = student.driverId,
               let driver = dataManager.drivers.first(
                   where: { $0.id == driverId }
               ) {

                VStack(alignment: .leading, spacing: 8) {

                    Text("Driver")
                        .font(.headline)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                    HStack(spacing: 10) {

                        Image(systemName: "car.fill")
                            .foregroundStyle(
                                SafeRiderTheme.orange
                            )

                        VStack(
                            alignment: .leading,
                            spacing: 2
                        ) {

                            Text(
                                driver.name.isEmpty
                                    ? driver.email
                                    : driver.name
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                            if !driver.vehicleNumber.isEmpty {
                                Text(driver.vehicleNumber)
                                    .font(.caption)
                                    .foregroundStyle(
                                        SafeRiderTheme.secondaryText
                                    )
                            }
                        }

                        Spacer()
                    }
                }
            }

            // MARK: Morning

            trackingSection(
                title: "Morning Transportation",
                icon: "sunrise.fill",
                student: student,
                isMorning: true
            )

            // MARK: Afternoon

            trackingSection(
                title: "Afternoon Transportation",
                icon: "sunset.fill",
                student: student,
                isMorning: false
            )
        }
        .padding()
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .shadow(
            color: .black.opacity(0.07),
            radius: 6,
            y: 3
        )
    }

    // MARK: - Tracking Section

    @ViewBuilder
    private func trackingSection(
        title: String,
        icon: String,
        student: Student,
        isMorning: Bool
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Label(
                title,
                systemImage: icon
            )
            .font(.headline)
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )

            let todayRide = todayRide(for: student)

            if let todayRide {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text("Status")
                            .font(.caption)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )

                        Text(todayRide.status.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                SafeRiderTheme.blue
                            )
                    }

                    Spacer()

                    Image(
                        systemName: statusIcon(
                            todayRide.status
                        )
                    )
                    .font(.title2)
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )
                }

                if !todayRide.pickupLocation.isEmpty {
                    locationRow(
                        title: "Pickup",
                        location: todayRide.pickupLocation,
                        icon: "mappin.and.ellipse"
                    )
                }

                if !todayRide.dropoffLocation.isEmpty {
                    locationRow(
                        title: "Destination",
                        location: todayRide.dropoffLocation,
                        icon: "flag.fill"
                    )
                }

                if let pickupTime = todayRide.pickupTime {
                    timeRow(
                        title: "Pickup Time",
                        time: pickupTime
                    )
                }

                if let dropoffTime = todayRide.dropoffTime {
                    timeRow(
                        title: "Drop-off Time",
                        time: dropoffTime
                    )
                }

            } else {

                HStack(spacing: 10) {

                    Image(systemName: "clock")
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )

                    Text(
                        isMorning
                            ? "No morning ride recorded today."
                            : "No afternoon ride recorded today."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                    Spacer()
                }
            }
        }
    }

    // MARK: - Today's Ride

    private func todayRide(
        for student: Student
    ) -> Ride? {

        dataManager.rides
            .filter {
                $0.studentId == student.id
                    && Calendar.current.isDate(
                        $0.date,
                        inSameDayAs: Date()
                    )
            }
            .sorted {
                $0.date > $1.date
            }
            .first
    }

    // MARK: - Location Row

    @ViewBuilder
    private func locationRow(
        title: String,
        location: String,
        icon: String
    ) -> some View {

        HStack(alignment: .top, spacing: 10) {

            Image(systemName: icon)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(width: 22)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                Text(location)
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
            }

            Spacer()
        }
    }

    // MARK: - Time Row

    @ViewBuilder
    private func timeRow(
        title: String,
        time: Date
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: "clock.fill")
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            Spacer()

            Text(
                time.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
        }
    }

    // MARK: - Status Icon

    private func statusIcon(
        _ status: RideStatus
    ) -> String {

        switch status {
        case .scheduled:
            return "clock.fill"

        case .driverEnRoute:
            return "car.fill"

        case .pickedUp:
            return "person.fill.checkmark"

        case .droppedAtSchool:
            return "building.2.fill"

        case .returning:
            return "arrow.uturn.backward.circle.fill"

        case .arrivedHome:
            return "house.fill"

        case .cancelled:
            return "xmark.circle.fill"
        }
    }
}
