import SwiftUI
import FirebaseFirestore
import CoreLocation

struct TrackingView: View {

    @EnvironmentObject private var dataManager: DataManager

    @StateObject private var locationManager =
        DriverLocationManager()

    private let db = Firestore.firestore()

    // MARK: - Selection

    @State private var selectedStudentID: UUID?
    @State private var activeRideID: UUID?
    @State private var isStartingRide = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var isUpdatingStatus = false
    @State private var showEndRideConfirmation = false

    // MARK: - Driver

    private var driver: Driver? {
        dataManager.currentDriver
    }

    // MARK: - Assigned Students

    private var assignedStudents: [Student] {
        dataManager.students
    }

    private var selectedStudent: Student? {
        guard let selectedStudentID else {
            return nil
        }

        return assignedStudents.first {
            $0.id == selectedStudentID
        }
    }

    // MARK: - Today's Schedules

    private var todayWeekday: Int {
        Calendar.current.component(
            .weekday,
            from: Date()
        )
    }

    private var todaysSchedules: [TransportationSchedule] {
        dataManager.transportationSchedules
            .filter { schedule in
                schedule.isActive &&
                schedule.weekdays.contains(todayWeekday) &&
                assignedStudents.contains {
                    $0.id == schedule.studentId
                }
            }
            .sorted { lhs, rhs in
                let lhsTime =
                    lhs.morningPickupTime ??
                    lhs.afternoonPickupTime ??
                    Date.distantFuture

                let rhsTime =
                    rhs.morningPickupTime ??
                    rhs.afternoonPickupTime ??
                    Date.distantFuture

                return lhsTime < rhsTime
            }
    }

    private func schedule(
        for student: Student
    ) -> TransportationSchedule? {
        dataManager.transportationSchedules.first {
            $0.studentId == student.id &&
            $0.isActive
        }
    }

    private func isScheduledToday(
        _ student: Student
    ) -> Bool {
        guard let schedule = schedule(for: student)
        else {
            return false
        }

        return schedule.weekdays.contains(
            todayWeekday
        )
    }

    // MARK: - Current Ride

    private var currentRide: Ride? {
        guard
            let student = selectedStudent,
            let driver
        else {
            return nil
        }

        if let activeRideID {
            if let ride = dataManager.rides.first(
                where: { $0.id == activeRideID }
            ) {
                return ride
            }
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

                driverHeader

                assignedStudentsSection

                todaysScheduleSection

                transportationSection

                liveLocationSection
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
            selectInitialStudent()
            restoreActiveRide()
        }
        .onChange(
            of: assignedStudents.map(\.id)
        ) { _, _ in
            selectInitialStudent()
            restoreActiveRide()
        }
        .onChange(
            of: selectedStudentID
        ) { _, _ in
            restoreActiveRide()
        }
        .onChange(
            of: locationManager.currentLocation
        ) { _, location in
            updateRideLocation(location)
        }
        .alert(
            "SafeRider",
            isPresented: $showAlert
        ) {
            Button("OK") { }
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    // MARK: - Next Available Transportation Action

    private var nextActionStatus: RideStatus? {
        switch rideStatus {
        case .scheduled:
            return .driverEnRoute

        case .driverEnRoute:
            return .pickedUp

        case .pickedUp:
            return .droppedAtSchool

        case .droppedAtSchool:
            return .returning

        case .returning:
            return .arrivedHome

        case .arrivedHome, .cancelled:
            return nil
        }
    }

    // MARK: - Driver Header

    private var driverHeader: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Text("Transportation")
                .font(
                    .system(
                        size: 28,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            if let driver {
                Text("Good day, \(driver.name)")
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
            } else {
                Text("Loading driver profile...")
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
            }
        }
    }

    // MARK: - Assigned Students

    private var assignedStudentsSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionTitle(
                "Assigned Students",
                icon: "person.2.fill"
            )

            if assignedStudents.isEmpty {
                emptyCard(
                    icon: "person.2.slash",
                    title: "No assigned students",
                    message:
                        "Students assigned to you will appear here."
                )
            } else {
                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {
                    HStack(spacing: 14) {
                        ForEach(
                            assignedStudents
                        ) { student in

                            studentCard(
                                student
                            )
                        }
                    }
                }
            }
        }
    }

    private func studentCard(
        _ student: Student
    ) -> some View {
        let isSelected =
            selectedStudentID == student.id

        let scheduledToday =
            isScheduledToday(student)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedStudentID = student.id
            }
        } label: {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                ZStack(
                    alignment: .bottomTrailing
                ) {
                    ProfileAvatarView(
                        name: student.name,
                        photoURL: student.photoURL,
                        size: 82
                    )

                    if scheduledToday {
                        Image(
                            systemName:
                                "calendar.badge.checkmark"
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(
                            SafeRiderTheme.success
                        )
                        .clipShape(Circle())
                    }
                }

                Text(student.name)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
                    .lineLimit(2)

                Text(
                    "\(student.grade) • \(student.section)"
                )
                .font(.caption)
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

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Circle()
                        .fill(
                            scheduledToday
                                ? SafeRiderTheme.success
                                : SafeRiderTheme.secondaryText
                        )
                        .frame(
                            width: 7,
                            height: 7
                        )

                    Text(
                        scheduledToday
                            ? "Scheduled today"
                            : "Not scheduled"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        scheduledToday
                            ? SafeRiderTheme.success
                            : SafeRiderTheme.secondaryText
                    )
                }
            }
            .frame(
                width: 190,
                height: 235,
                alignment: .topLeading
            )
            .padding(16)
            .background(
                SafeRiderTheme.surface
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18
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
                    cornerRadius: 18
                )
            )
            .shadow(
                color: .black.opacity(
                    isSelected ? 0.10 : 0.04
                ),
                radius: 5,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Today's Schedule

    private var todaysScheduleSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            sectionTitle(
                "Today's Schedule",
                icon: "calendar"
            )

            if todaysSchedules.isEmpty {
                emptyCard(
                    icon: "calendar.badge.exclamationmark",
                    title: "No transportation scheduled",
                    message:
                        "There are no students scheduled for transportation today."
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(
                        todaysSchedules
                    ) { schedule in

                        scheduleCard(
                            schedule
                        )
                    }
                }
            }
        }
    }

    private func scheduleCard(
        _ schedule: TransportationSchedule
    ) -> some View {

        let student =
            assignedStudents.first {
                $0.id == schedule.studentId
            }

        return Button {
            if let student {
                selectedStudentID = student.id
            }
        } label: {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                HStack(spacing: 12) {

                    if let student {
                        ProfileAvatarView(
                            name: student.name,
                            photoURL: student.photoURL,
                            size: 48
                        )
                    } else {
                        Image(
                            systemName:
                                "person.fill"
                        )
                        .font(
                            .system(
                                size: 20,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )
                        .frame(
                            width: 48,
                            height: 48
                        )
                        .background(
                            SafeRiderTheme.orange
                                .opacity(0.12)
                        )
                        .clipShape(Circle())
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {
                        Text(
                            student?.name ??
                            "Assigned Student"
                        )
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                        Text(
                            "Transportation scheduled today"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }

                    Spacer()
                }

                if let morning =
                    schedule.morningPickupTime {

                    scheduleTripRow(
                        icon: "sunrise.fill",
                        title: "Morning Pickup",
                        time: morning,
                        route:
                            morningRoute(schedule)
                    )
                }

                if let afternoon =
                    schedule.afternoonPickupTime {

                    if schedule.morningPickupTime != nil {
                        Divider()
                    }

                    scheduleTripRow(
                        icon: "sunset.fill",
                        title: "Afternoon Drop-off",
                        time: afternoon,
                        route:
                            afternoonRoute(schedule)
                    )
                }
            }
            .padding(16)
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func scheduleTripRow(
        icon: String,
        title: String,
        time: Date,
        route: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(systemName: icon)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    SafeRiderTheme.orange
                        .opacity(0.12)
                )
                .clipShape(Circle())

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                    .font(
                        .system(
                            size: 14,
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
                    .lineLimit(1)
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
                    size: 14,
                    weight: .bold
                )
            )
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
        }
    }

    // MARK: - Transportation

    private var transportationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            sectionTitle(
                "Transportation",
                icon: "car.fill"
            )

            if selectedStudent == nil {
                emptyCard(
                    icon: "person.crop.circle.badge.exclamationmark",
                    title: "Select a student",
                    message:
                        "Select a student above before starting transportation."
                )
            } else {

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    transportationAction(
                        icon: "car.fill",
                        title: "En Route",
                        status: .driverEnRoute
                    )
                    
                    transportationAction(
                        icon: "person.fill",
                        title: "Picked Up",
                        status: .pickedUp
                    )
                    
                    transportationAction(
                        icon: "building.2.fill",
                        title: "At School",
                        status: .droppedAtSchool
                    )
                    
                    transportationAction(
                        icon: "arrow.uturn.left.circle.fill",
                        title: "Returning",
                        status: .returning
                    )
                }

                // Full-width Arrived Home button
                transportationAction(
                    icon: "house.fill",
                    title: "Arrived Home",
                    status: .arrivedHome
                )
                .frame(maxWidth: .infinity)

                // Full-width Stop Ride button
                stopRideAction
                    .frame(maxWidth: .infinity)
                
            }
        }
    }

    // MARK: - Transportation Action

    private func transportationAction(
        icon: String,
        title: String,
        status: RideStatus
    ) -> some View {

        let isActive = nextActionStatus == status

        return Button {
            guard isActive else { return }

            updateTransportationStatus(status)

        } label: {

            VStack(spacing: 10) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 27,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        isActive
                            ? .white
                            : Color.gray
                    )

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        isActive
                            ? .white
                            : Color.gray
                    )
                    .multilineTextAlignment(.center)

                if isActive {
                    Text("NEXT ACTION")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 105
            )
            .padding(10)
            .background(
                isActive
                    ? SafeRiderTheme.orange
                    : Color.gray.opacity(0.15)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }

    private var stopRideAction: some View {
        Button {
            showEndRideConfirmation = true
        } label: {
            // Keep your existing Stop Ride button design.
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "End Transportation?",
            isPresented: $showEndRideConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Ride", role: .destructive) {
                endTransportation()
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Are you sure you want to end this transportation session? "
                + "This will mark the ride as completed, stop live GPS tracking, "
                + "and remove the driver's active transportation status."
            )
        }
    }
    
    // MARK: - End Transportation

    private func endTransportation() {
        guard
            let rideID = activeRideID,
            let student = selectedStudent,
            let driver
        else {
            showError("No active transportation session was found.")
            return
        }

        // Prevent duplicate completion attempts.
        guard !isUpdatingStatus else {
            return
        }

        isUpdatingStatus = true

        // Mark the ride as completed.
        _ = dataManager.updateTodayRide(
            studentId: student.id,
            driverId: driver.id,
            status: .arrivedHome
        )

        // Stop GPS tracking.
        locationManager.stopTracking()

        // Clear the active ride reference.
        activeRideID = nil

        isUpdatingStatus = false

        print("🏁 Transportation ended for ride: \(rideID)")
    }

    // MARK: - Live GPS

    private var liveLocationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                sectionTitle(
                    "Live GPS",
                    icon: "location.fill"
                )

                Spacer()

                HStack(spacing: 6) {

                    Circle()
                        .fill(
                            locationManager.isTracking
                                ? SafeRiderTheme.success
                                : SafeRiderTheme.secondaryText
                        )
                        .frame(
                            width: 8,
                            height: 8
                        )

                    Text(
                        locationManager.isTracking
                            ? "LIVE"
                            : "OFFLINE"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        locationManager.isTracking
                            ? SafeRiderTheme.success
                            : SafeRiderTheme.secondaryText
                    )
                }
            }

            VStack(spacing: 12) {

                Image(
                    systemName:
                        locationManager.currentLocation == nil
                            ? "location.slash.fill"
                            : "location.fill"
                )
                .font(
                    .system(
                        size: 34,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    locationManager.currentLocation == nil
                        ? SafeRiderTheme.secondaryText
                        : SafeRiderTheme.blue
                )

                if let location =
                    locationManager.currentLocation {

                    Text("GPS Location Available")
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                    Text(
                        String(
                            format:
                                "Latitude: %.6f\nLongitude: %.6f",
                            location.coordinate.latitude,
                            location.coordinate.longitude
                        )
                    )
                    .font(
                        .system(
                            size: 13,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .multilineTextAlignment(
                        .center
                    )

                    Text(
                        String(
                            format:
                                "Accuracy: %.0f m",
                            location.horizontalAccuracy
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                } else {

                    Text(
                        locationManager.isTracking
                            ? "Waiting for GPS..."
                            : "GPS tracking is not active"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                    Text(
                        "Your live location will be transmitted while transportation is active."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .multilineTextAlignment(
                        .center
                    )
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
                    cornerRadius: 16
                )
            )
        }
    }

    // MARK: - Start Transportation

    // MARK: - Start Transportation

    private func startTransportation() {
        print("🚦 START TRANSPORTATION tapped")

        guard let selectedStudentID else {
            showError("Please select a student first.")
            return
        }

        guard let student = assignedStudents.first(
            where: { $0.id == selectedStudentID }
        ) else {
            showError(
                "The selected student is no longer available."
            )
            return
        }

        guard let driver else {
            showError(
                "Please make sure your driver profile is loaded."
            )
            return
        }

        isStartingRide = true

        let authorization =
            locationManager.authorizationStatus

        switch authorization {

        case .notDetermined:
            locationManager.requestPermission()

            let rideID =
                dataManager.updateTodayRide(
                    studentId: student.id,
                    driverId: driver.id,
                    status: .driverEnRoute
                )

            activeRideID = rideID
            isStartingRide = false

        case .denied, .restricted:
            isStartingRide = false

            showError(
                "SafeRider does not have permission to access your location. Please enable Location Services for SafeRider in Settings."
            )

        case .authorizedWhenInUse,
             .authorizedAlways:

            let rideID =
                dataManager.updateTodayRide(
                    studentId: student.id,
                    driverId: driver.id,
                    status: .driverEnRoute
                )

            activeRideID = rideID

            locationManager.startTracking()

            isStartingRide = false

        @unknown default:
            isStartingRide = false

            showError(
                "Unable to determine location authorization."
            )
        }
    }

    // MARK: - Status Update

    private func updateTransportationStatus(
        _ status: RideStatus
    ) {
        // Prevent duplicate status updates.
        guard !isUpdatingStatus else {
            return
        }

        // Only allow the next valid domino step.
        guard nextActionStatus == status else {
            print("⚠️ Invalid or duplicate transportation action.")
            return
        }

        guard let selectedStudentID else {
            showError("Please select a student first.")
            return
        }

        guard let student = assignedStudents.first(
            where: { $0.id == selectedStudentID }
        ) else {
            showError(
                "The selected student is no longer available."
            )
            return
        }

        guard let driver else {
            showError(
                "Your driver profile is still loading. Please try again."
            )
            return
        }

        // Lock the buttons while processing.
        isUpdatingStatus = true

        print(
            "🚦 Updating \(student.name) → \(status.rawValue)"
        )

        let rideID = dataManager.updateTodayRide(
            studentId: student.id,
            driverId: driver.id,
            status: status
        )

        activeRideID = rideID

        if status == .driverEnRoute &&
            !locationManager.isTracking {
            locationManager.startTracking()
        }

        // DataManager currently appears to update synchronously.
        // Release the temporary UI lock after the call returns.
        isUpdatingStatus = false
    }

    // MARK: - Stop

    private func stopTransportation() {

        locationManager.stopTracking()

        activeRideID = nil

        print(
            "🛑 Transportation tracking stopped."
        )
    }

    // MARK: - Restore Ride

    private func restoreActiveRide() {

        guard
            let student = selectedStudent,
            let driver
        else {
            activeRideID = nil
            return
        }

        if let ride = dataManager.rides.first(
            where: {
                $0.studentId == student.id &&
                $0.driverId == driver.id &&
                Calendar.current.isDate(
                    $0.date,
                    inSameDayAs: Date()
                )
            }
        ) {
            activeRideID = ride.id

            if ride.status != .arrivedHome &&
                ride.status != .cancelled {

                if !locationManager.isTracking {
                    locationManager.startTracking()
                }
            }
        } else {
            activeRideID = nil
        }
    }

    // MARK: - GPS → Firestore

    private func updateRideLocation(
        _ location: CLLocation?
    ) {
        guard
            let location,
            location.horizontalAccuracy >= 0,
            locationManager.isTracking,
            let selectedStudentID,
            let driver,
            let rideID = activeRideID
        else {
            return
        }

        guard assignedStudents.contains(
            where: { $0.id == selectedStudentID }
        ) else {
            return
        }

        let locationData: [String: Any] = [
            "latitude":
                location.coordinate.latitude,
            "longitude":
                location.coordinate.longitude,
            "accuracy":
                location.horizontalAccuracy,
            "updatedAt":
                Timestamp(date: Date())
        ]

        let data: [String: Any] = [
            "driverAuthUID":
                driver.authUID ?? "",
            "driverId":
                driver.id.uuidString,
            "studentId":
                selectedStudentID.uuidString,
            "currentLocation":
                locationData,
            "updatedAt":
                Timestamp(date: Date())
        ]

        db.collection("rides")
            .document(rideID.uuidString)
            .setData(
                data,
                merge: true
            ) { error in
                if let error {
                    print(
                        """
                        ❌ GPS location save failed:
                        \(error.localizedDescription)
                        """
                    )
                } else {
                    print(
                        "📍 GPS location saved."
                    )
                }
            }
    }

    // MARK: - Initial Selection

    private func selectInitialStudent() {

        guard !assignedStudents.isEmpty
        else {
            selectedStudentID = nil
            return
        }

        if let selectedStudentID,
           assignedStudents.contains(
               where: {
                   $0.id == selectedStudentID
               }
           ) {
            return
        }

        selectedStudentID =
            assignedStudents.first?.id
    }

    // MARK: - Routes

    private func morningRoute(
        _ schedule: TransportationSchedule
    ) -> String {

        if !schedule.homeLocation.isEmpty &&
            !schedule.schoolLocation.isEmpty {

            return
                "\(schedule.homeLocation) → " +
                "\(schedule.schoolLocation)"
        }

        return "Home → School"
    }

    private func afternoonRoute(
        _ schedule: TransportationSchedule
    ) -> String {

        if !schedule.schoolLocation.isEmpty &&
            !schedule.homeLocation.isEmpty {

            return
                "\(schedule.schoolLocation) → " +
                "\(schedule.homeLocation)"
        }

        return "School → Home"
    }

    // MARK: - Section Title

    private func sectionTitle(
        _ title: String,
        icon: String
    ) -> some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )

            Text(title)
                .font(
                    .system(
                        size: 18,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
        }
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
                .multilineTextAlignment(
                    .center
                )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(22)
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Error

    private func showError(
        _ message: String
    ) {
        alertMessage = message
        showAlert = true
    }
}
