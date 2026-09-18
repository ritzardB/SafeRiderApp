//
//  TransportationTrackingView.swift
//  SafeRider
//
//  Parent transportation tracking
//

import SwiftUI
import FirebaseFirestore
import CoreLocation

struct TransportationTrackingView: View {

    @EnvironmentObject private var dataManager: DataManager

    private let db = Firestore.firestore()

    // MARK: - Input

    private let initialStudent: Student?

    @State private var selectedStudentID: UUID?
    @State private var rideListener: ListenerRegistration?
    @State private var firestoreRide: Ride?
    @State private var activeRideID: UUID?

    @State private var liveLatitude: Double?
    @State private var liveLongitude: Double?
    @State private var liveAccuracy: Double?
    @State private var liveUpdatedAt: Date?

    @State private var listenerError: String?

    // MARK: - Initialization

    init(student: Student? = nil) {
        self.initialStudent = student

        _selectedStudentID = State(
            initialValue: student?.id
        )
    }

    // MARK: - Parent

    private var parent: Parent? {
        dataManager.currentParent
    }

    // MARK: - Children

    private var children: [Student] {
        guard let parent else {
            return []
        }

        return dataManager.students(for: parent)
    }

    // MARK: - Available Students

    private var availableStudents: [Student] {
        var result = children

        if let initialStudent,
           !result.contains(where: {
               $0.id == initialStudent.id
           }) {
            result.append(initialStudent)
        }

        return result
    }

    // MARK: - Selected Student

    private var selectedStudent: Student? {

        if let selectedStudentID,
           let student = availableStudents.first(
               where: {
                   $0.id == selectedStudentID
               }
           ) {
            return student
        }

        return initialStudent ?? availableStudents.first
    }

    // MARK: - Assigned Driver

    private var assignedDriver: Driver? {

        guard let student = selectedStudent else {
            return nil
        }

        return dataManager.driver(
            for: student
        )
    }

    // MARK: - Schedule

    private var transportationSchedule:
        TransportationSchedule? {

        guard let student = selectedStudent else {
            return nil
        }

        return dataManager.transportationSchedules.first {
            $0.studentId == student.id &&
            $0.isActive
        }
    }

    // MARK: - Today

    private var todayWeekday: Int {
        Calendar.current.component(
            .weekday,
            from: Date()
        )
    }

    private var scheduleRunsToday: Bool {

        guard let schedule = transportationSchedule else {
            return false
        }

        return schedule.weekdays.contains(
            todayWeekday
        )
    }

    // MARK: - Current Ride

    private var currentRide: Ride? {
        firestoreRide ?? localTodayRide
    }

    private var localTodayRide: Ride? {

        guard
            let student = selectedStudent,
            let driver = assignedDriver
        else {
            return nil
        }

        return dataManager.rides.first {
            $0.studentId == student.id &&
            $0.driverId == driver.id &&
            Calendar.current.isDate(
                $0.date,
                inSameDayAs: Date()
            )
        }
    }

    // MARK: - Status

    private var rideStatus: RideStatus {
        currentRide?.status ?? .scheduled
    }

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                childrenCarousel

                currentTransportationSection

                transportationProgress

                driverSection

                scheduleSection

                rideDetailsSection

                liveLocationSection

                if let listenerError {
                    errorCard(listenerError)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()
        )
        .navigationTitle("Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {

            if selectedStudentID == nil {
                selectedStudentID =
                    availableStudents.first?.id
            }

            startRideListener()
        }
        .onChange(
            of: selectedStudentID
        ) { _, _ in
            startRideListener()
        }
        .onChange(
            of: availableStudents.map(\.id)
        ) { _, ids in

            if selectedStudentID == nil {
                selectedStudentID = ids.first
            }
        }
        .onDisappear {
            removeRideListener()
        }
    }

    // MARK: - Children Carousel

    private var childrenCarousel: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text("Your Children")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Spacer()

                if !availableStudents.isEmpty {
                    Text("\(availableStudents.count)")
                        .font(
                            .system(
                                size: 13,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            SafeRiderTheme.orange
                                .opacity(0.12)
                        )
                        .clipShape(Capsule())
                }
            }

            if availableStudents.isEmpty {

                emptyCard(
                    icon:
                        "person.crop.circle.badge.exclamationmark",
                    title:
                        "No children found",
                    message:
                        "No children are currently associated with your parent account."
                )

            } else {

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {

                    HStack(
                        spacing: 14
                    ) {

                        ForEach(
                            availableStudents
                        ) { student in

                            Button {

                                selectedStudentID =
                                    student.id

                            } label: {

                                childCarouselCard(
                                    student
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollClipDisabled()
            }
        }
    }

    private func childCarouselCard(
        _ student: Student
    ) -> some View {

        let isSelected =
            selectedStudentID == student.id

        let hasSchedule =
            dataManager.transportationSchedules.contains {
                $0.studentId == student.id &&
                $0.isActive &&
                $0.weekdays.contains(todayWeekday)
            }

        return VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                ProfileAvatarView(
                    name: student.name,
                    photoURL: student.photoURL,
                    size: 70
                )

                Spacer()

                if isSelected {

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(student.name)
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
                    .lineLimit(2)

                Text(
                    "Grade \(student.grade) • \(student.section)"
                )
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

                if !student.school.isEmpty {

                    Text(student.school)
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 2)

            HStack(spacing: 6) {

                Circle()
                    .fill(
                        hasSchedule
                        ? SafeRiderTheme.success
                        : SafeRiderTheme.secondaryText
                    )
                    .frame(
                        width: 7,
                        height: 7
                    )

                Text(
                    hasSchedule
                    ? "Scheduled today"
                    : "No ride scheduled"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    hasSchedule
                    ? SafeRiderTheme.success
                    : SafeRiderTheme.secondaryText
                )
            }
        }
        .frame(
            width: 225,
            height: 190
        )
        .padding(16)
        .background(
            SafeRiderTheme.surface
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                isSelected
                ? SafeRiderTheme.orange
                : Color.clear,
                lineWidth: 3
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 8,
            y: 3
        )
    }

    // MARK: - Current Transportation

    private var currentTransportationSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Today's Transportation")
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                HStack {

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {

                        Text(
                            selectedStudent?.name
                            ?? "Child"
                        )
                        .font(
                            .system(
                                size: 20,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                        Text(
                            statusTitle(rideStatus)
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            statusColor(rideStatus)
                        )
                    }

                    Spacer()

                    Image(
                        systemName:
                            statusIcon(rideStatus)
                    )
                    .font(
                        .system(
                            size: 26,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        statusColor(rideStatus)
                    )
                    .frame(
                        width: 52,
                        height: 52
                    )
                    .background(
                        statusColor(rideStatus)
                            .opacity(0.12)
                    )
                    .clipShape(Circle())
                }

                Text(
                    statusMessage(rideStatus)
                )
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
            }
            .padding(20)
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22
                )
            )
            .shadow(
                color: .black.opacity(0.04),
                radius: 8,
                y: 3
            )
        }
    }

    // MARK: - Transportation Progress

    private var transportationProgress:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Transportation Progress")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            VStack(spacing: 0) {

                progressStep(
                    title: "Scheduled",
                    icon: "calendar.badge.clock",
                    status: .scheduled
                )

                progressStep(
                    title: "En Route",
                    icon: "car.fill",
                    status: .driverEnRoute
                )

                progressStep(
                    title: "Picked Up",
                    icon: "person.fill",
                    status: .pickedUp
                )

                progressStep(
                    title: "At School",
                    icon: "building.2.fill",
                    status: .droppedAtSchool
                )

                progressStep(
                    title: "Returning",
                    icon: "arrow.uturn.left.circle.fill",
                    status: .returning
                )

                progressStep(
                    title: "Arrived Home",
                    icon: "house.fill",
                    status: .arrivedHome
                )
            }
            .padding(18)
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
    }

    private func progressStep(
        title: String,
        icon: String,
        status: RideStatus
    ) -> some View {

        let isCurrent =
            rideStatus == status

        let isCompleted =
            statusRank(rideStatus) >
            statusRank(status)

        return HStack(
            spacing: 12
        ) {

            VStack(spacing: 0) {

                Image(
                    systemName: icon
                )
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    isCurrent || isCompleted
                    ? statusColor(rideStatus)
                    : SafeRiderTheme.secondaryText
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    isCurrent
                    ? statusColor(rideStatus)
                        .opacity(0.14)
                    : isCompleted
                    ? SafeRiderTheme.success
                        .opacity(0.12)
                    : SafeRiderTheme.secondaryText
                        .opacity(0.08)
                )
                .clipShape(Circle())
            }

            Text(title)
                .font(
                    .system(
                        size: 14,
                        weight:
                            isCurrent
                            ? .bold
                            : .medium
                    )
                )
                .foregroundStyle(
                    isCurrent
                    ? SafeRiderTheme.primaryText
                    : isCompleted
                    ? SafeRiderTheme.secondaryText
                    : SafeRiderTheme.secondaryText
                )

            Spacer()

            if isCurrent {

                Text("CURRENT")
                    .font(
                        .system(
                            size: 9,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        statusColor(rideStatus)
                    )
                    .padding(
                        .horizontal,
                        8
                    )
                    .padding(
                        .vertical,
                        5
                    )
                    .background(
                        statusColor(rideStatus)
                            .opacity(0.10)
                    )
                    .clipShape(Capsule())

            } else if isCompleted {

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.success
                )
            }
        }
        .padding(.vertical, 5)
    }

    // MARK: - Driver

    private var driverSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Your Driver")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            if let driver = assignedDriver {

                HStack(spacing: 14) {

                    ProfileAvatarView(
                        name: driver.name,
                        photoURL: driver.photoURL,
                        size: 58
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {

                        Text(driver.name)
                            .font(
                                .system(
                                    size: 17,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        if !driver.vehicleType.isEmpty {

                            Text(driver.vehicleType)
                                .font(.caption)
                                .foregroundStyle(
                                    SafeRiderTheme.secondaryText
                                )
                        }

                        if !driver.vehicleNumber.isEmpty {

                            Label(
                                driver.vehicleNumber,
                                systemImage: "car.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                        }
                    }

                    Spacer()

                    Image(
                        systemName:
                            "checkmark.shield.fill"
                    )
                    .foregroundStyle(
                        SafeRiderTheme.success
                    )
                }
                .padding(18)
                .background(
                    SafeRiderTheme.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20
                    )
                )

            } else {

                emptyCard(
                    icon:
                        "car.badge.questionmark",
                    title:
                        "No driver assigned",
                    message:
                        "This child does not currently have an assigned driver."
                )
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Today's Schedule")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            if let schedule = transportationSchedule {

                VStack(spacing: 0) {

                    if let morning =
                        schedule.morningPickupTime {

                        scheduleRow(
                            icon: "sunrise.fill",
                            title: "Morning Pickup",
                            time: morning,
                            route: morningRoute(
                                schedule
                            )
                        )
                    }

                    if let afternoon =
                        schedule.afternoonPickupTime {

                        if schedule.morningPickupTime != nil {
                            Divider()
                                .padding(.leading, 54)
                        }

                        scheduleRow(
                            icon: "sunset.fill",
                            title: "Afternoon Pickup",
                            time: afternoon,
                            route: afternoonRoute(
                                schedule
                            )
                        )
                    }
                }
                .background(
                    SafeRiderTheme.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20
                    )
                )

                if !scheduleRunsToday {

                    HStack(spacing: 8) {

                        Image(
                            systemName:
                                "calendar.badge.exclamationmark"
                        )

                        Text(
                            "This schedule does not run today."
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.danger
                    )
                    .padding(.horizontal, 4)
                }

            } else {

                emptyCard(
                    icon:
                        "calendar.badge.exclamationmark",
                    title:
                        "No schedule",
                    message:
                        "No active transportation schedule was found for this child."
                )
            }
        }
    }

    // MARK: - Ride Details

    private var rideDetailsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Ride Details")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            VStack(spacing: 0) {

                detailRow(
                    icon: "clock.fill",
                    title: "Pickup Time",
                    value:
                        currentRide?
                            .pickupTime?
                            .formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        ?? "Not recorded"
                )

                Divider()

                detailRow(
                    icon:
                        "checkmark.circle.fill",
                    title: "Drop-off Time",
                    value:
                        currentRide?
                            .dropoffTime?
                            .formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        ?? "Not recorded"
                )

                if let location =
                    transportationSchedule?
                        .pickupLocation,
                   !location.isEmpty {

                    Divider()

                    detailRow(
                        icon:
                            "mappin.and.ellipse",
                        title:
                            "Pickup Location",
                        value:
                            location
                    )
                }

                if let school =
                    transportationSchedule?
                        .schoolLocation,
                   !school.isEmpty {

                    Divider()

                    detailRow(
                        icon:
                            "building.2.fill",
                        title:
                            "School",
                        value:
                            school
                    )
                }
            }
            .padding(.horizontal, 16)
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
    }

    // MARK: - Live Location

    private var liveLocationSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            // MARK: - Header

            HStack {

                Text("Live GPS")
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Spacer()

                HStack(spacing: 6) {

                    Circle()
                        .fill(
                            liveLatitude != nil
                            ? SafeRiderTheme.success
                            : SafeRiderTheme.secondaryText
                        )
                        .frame(
                            width: 8,
                            height: 8
                        )

                    Text(
                        liveLatitude != nil
                        ? "LIVE"
                        : "OFFLINE"
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        liveLatitude != nil
                        ? SafeRiderTheme.success
                        : SafeRiderTheme.secondaryText
                    )
                }
            }

            // MARK: - Map

            SafeRiderMapView(
                homeAddress:
                    transportationSchedule?.homeLocation ?? "",
                schoolAddress:
                    transportationSchedule?.schoolLocation ?? "",
                driverLatitude:
                    liveLatitude,
                driverLongitude:
                    liveLongitude
            )
            
            VStack(spacing: 14) {

                ZStack {

                    Circle()
                        .fill(
                            liveLatitude != nil
                            ? SafeRiderTheme.blue
                                .opacity(0.10)
                            : SafeRiderTheme.secondaryText
                                .opacity(0.08)
                        )
                        .frame(
                            width: 76,
                            height: 76
                        )

                    Image(
                        systemName:
                            liveLatitude != nil
                            ? "location.fill"
                            : "location.slash.fill"
                    )
                    .font(
                        .system(
                            size: 28,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        liveLatitude != nil
                        ? SafeRiderTheme.blue
                        : SafeRiderTheme.secondaryText
                    )
                }

                if let latitude = liveLatitude,
                   let longitude = liveLongitude {

                    Text("Driver location available")
                        .font(
                            .system(
                                size: 16,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                    Text(
                        String(
                            format:
                                "Latitude: %.6f\nLongitude: %.6f",
                            latitude,
                            longitude
                        )
                    )
                    .font(
                        .system(
                            size: 12,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .multilineTextAlignment(.center)

                    if let accuracy = liveAccuracy {

                        Text(
                            "Accuracy: \(Int(accuracy)) m"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }

                    if let updated = liveUpdatedAt {
                            Text("Updated \(updated.formatted(date: .omitted, time: .standard))")
                                .font(.caption)
                                .foregroundStyle(SafeRiderTheme.secondaryText)
                        }

                } else {

                    Text(
                        rideStatus == .scheduled
                        ? "Live tracking has not started"
                        : "Waiting for driver location"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                    Text(
                        "The driver's live GPS location will appear here while transportation is active."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .multilineTextAlignment(.center)
                }
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(24)
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
    }

    // MARK: - Firestore Ride Listener

    private func startRideListener() {

        removeRideListener()

        guard let student = selectedStudent else {
            return
        }

        listenerError = nil

        print(
            """
            👨‍👩‍👧 Parent tracking listener:

            Student: \(student.name)
            Student ID: \(student.id)
            """
        )

        var query =
            db.collection("rides")
                .whereField(
                    "studentId",
                    isEqualTo:
                        student.id.uuidString
                )

        if let driver = assignedDriver {

            query = query.whereField(
                "driverId",
                isEqualTo:
                    driver.id.uuidString
            )
        }

        rideListener =
            query.addSnapshotListener {
                snapshot,
                error in

                if let error {

                    print(
                        """
                        ❌ Parent ride listener:
                        \(error.localizedDescription)
                        """
                    )

                    DispatchQueue.main.async {
                        self.listenerError =
                            error.localizedDescription
                    }

                    return
                }

                guard let snapshot else {
                    return
                }

                let rides =
                    snapshot.documents.compactMap {
                        self.decodeRide(
                            from: $0.data()
                        )
                    }

                let today =
                    rides.first {
                        Calendar.current.isDate(
                            $0.date,
                            inSameDayAs: Date()
                        )
                    }

                DispatchQueue.main.async {

                    self.firestoreRide = today

                    if let today {

                        self.activeRideID = today.id

                        print(
                            """
                            🚗 Parent received ride:
                            \(today.id)
                            Status: \(today.status.rawValue)
                            """
                        )

                    } else {

                        self.activeRideID = nil
                    }

                    if let document =
                        snapshot.documents.first(
                            where: {
                                UUID(
                                    uuidString:
                                        $0.documentID
                                )
                                == today?.id
                            }
                        ) {

                        self.readLocation(
                            from:
                                document.data()
                        )
                    } else {

                        self.liveLatitude = nil
                        self.liveLongitude = nil
                        self.liveAccuracy = nil
                        self.liveUpdatedAt = nil
                    }
                }
            }
    }

    // MARK: - Remove Listener

    private func removeRideListener() {

        rideListener?.remove()
        rideListener = nil
    }

    // MARK: - Read Location

    private func readLocation(
        from data: [String: Any]
    ) {

        guard
            let location =
                data["currentLocation"]
                as? [String: Any]
        else {

            DispatchQueue.main.async {

                self.liveLatitude = nil
                self.liveLongitude = nil
                self.liveAccuracy = nil
                self.liveUpdatedAt = nil
            }

            return
        }

        let latitude =
            location["latitude"]
            as? Double

        let longitude =
            location["longitude"]
            as? Double

        let accuracy =
            location["accuracy"]
            as? Double

        let updatedAt =
            (location["updatedAt"]
                as? Timestamp)?
                .dateValue()

        DispatchQueue.main.async {

            self.liveLatitude =
                latitude

            self.liveLongitude =
                longitude

            self.liveAccuracy =
                accuracy

            self.liveUpdatedAt =
                updatedAt
        }
    }

    // MARK: - Ride Decoder

    private func decodeRide(
        from data: [String: Any]
    ) -> Ride? {

        guard
            let idString =
                data["id"] as? String,

            let id =
                UUID(
                    uuidString: idString
                ),

            let studentString =
                data["studentId"] as? String,

            let studentId =
                UUID(
                    uuidString: studentString
                ),

            let driverString =
                data["driverId"] as? String,

            let driverId =
                UUID(
                    uuidString: driverString
                ),

            let statusString =
                data["status"] as? String,

            let status =
                RideStatus(
                    rawValue:
                        statusString
                )
        else {
            return nil
        }

        let date =
            (data["date"] as? Timestamp)?
                .dateValue()
            ?? Date()

        let parentId =
            (data["parentId"] as? String)
                .flatMap {
                    UUID(
                        uuidString: $0
                    )
                }

        let pickupTime =
            (data["pickupTime"] as? Timestamp)?
                .dateValue()

        let dropoffTime =
            (data["dropoffTime"] as? Timestamp)?
                .dateValue()

        let pickupLocation =
            data["pickupLocation"]
            as? String
            ?? ""

        let dropoffLocation =
            data["dropoffLocation"]
            as? String
            ?? ""

        let notes =
            data["notes"]
            as? String
            ?? ""

        return Ride(
            id: id,
            studentId: studentId,
            driverId: driverId,
            parentId: parentId,
            date: date,
            status: status,
            pickupTime: pickupTime,
            dropoffTime: dropoffTime,
            pickupLocation:
                pickupLocation,
            dropoffLocation:
                dropoffLocation,
            notes: notes
        )
    }

    // MARK: - Schedule Row

    private func scheduleRow(
        icon: String,
        title: String,
        time: Date,
        route: String
    ) -> some View {

        HStack(spacing: 14) {

            Image(systemName: icon)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(
                    width: 40,
                    height: 40
                )
                .background(
                    SafeRiderTheme.orange
                        .opacity(0.12)
                )
                .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Text(route)
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .lineLimit(2)
            }

            Spacer()

            Text(
                time.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
            .font(
                .system(
                    size: 15,
                    weight: .bold
                )
            )
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
        }
        .padding(16)
    }

    // MARK: - Detail Row

    private func detailRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            Spacer()

            Text(value)
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Routes

    private func morningRoute(
        _ schedule: TransportationSchedule
    ) -> String {

        if !schedule.homeLocation.isEmpty &&
            !schedule.schoolLocation.isEmpty {

            return """
            \(schedule.homeLocation) → \(schedule.schoolLocation)
            """
        }

        return "Home → School"
    }

    private func afternoonRoute(
        _ schedule: TransportationSchedule
    ) -> String {

        if !schedule.schoolLocation.isEmpty &&
            !schedule.homeLocation.isEmpty {

            return """
            \(schedule.schoolLocation) → \(schedule.homeLocation)
            """
        }

        return "School → Home"
    }

    // MARK: - Status Helpers

    private func statusTitle(
        _ status: RideStatus
    ) -> String {

        switch status {

        case .scheduled:
            return "Scheduled"

        case .driverEnRoute:
            return "Driver is on the way"

        case .pickedUp:
            return "Child picked up"

        case .droppedAtSchool:
            return "Arrived at school"

        case .returning:
            return "Returning home"

        case .arrivedHome:
            return "Arrived home"

        case .cancelled:
            return "Ride cancelled"
        }
    }

    private func statusMessage(
        _ status: RideStatus
    ) -> String {

        switch status {

        case .scheduled:
            return "Transportation is scheduled for today."

        case .driverEnRoute:
            return "Your driver is heading to the pickup location."

        case .pickedUp:
            return "Your child has been picked up."

        case .droppedAtSchool:
            return "Your child has arrived at school."

        case .returning:
            return "Your child is returning home."

        case .arrivedHome:
            return "Your child has returned home safely."

        case .cancelled:
            return "Today's ride has been cancelled."
        }
    }

    private func statusIcon(
        _ status: RideStatus
    ) -> String {

        switch status {

        case .scheduled:
            return "calendar.badge.clock"

        case .driverEnRoute:
            return "car.fill"

        case .pickedUp:
            return "person.fill"

        case .droppedAtSchool:
            return "building.2.fill"

        case .returning:
            return "arrow.uturn.left.circle.fill"

        case .arrivedHome:
            return "house.fill"

        case .cancelled:
            return "xmark.circle.fill"
        }
    }

    private func statusColor(
        _ status: RideStatus
    ) -> Color {

        switch status {

        case .scheduled:
            return SafeRiderTheme.orange

        case .driverEnRoute:
            return SafeRiderTheme.orange

        case .pickedUp:
            return SafeRiderTheme.blue

        case .droppedAtSchool:
            return SafeRiderTheme.blue

        case .returning:
            return SafeRiderTheme.blue

        case .arrivedHome:
            return SafeRiderTheme.success

        case .cancelled:
            return SafeRiderTheme.danger
        }
    }

    // MARK: - Status Rank

    private func statusRank(
        _ status: RideStatus
    ) -> Int {

        switch status {

        case .scheduled:
            return 0

        case .driverEnRoute:
            return 1

        case .pickedUp:
            return 2

        case .droppedAtSchool:
            return 3

        case .returning:
            return 4

        case .arrivedHome:
            return 5

        case .cancelled:
            return -1
        }
    }

    // MARK: - Error Card

    private func errorCard(
        _ message: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(
                SafeRiderTheme.danger
            )

            Text(message)
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.danger
                )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            SafeRiderTheme.danger.opacity(0.08)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    // MARK: - Empty Card

    private func emptyCard(
        icon: String,
        title: String,
        message: String
    ) -> some View {

        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(
                    .system(
                        size: 28,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            Text(message)
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }
}
