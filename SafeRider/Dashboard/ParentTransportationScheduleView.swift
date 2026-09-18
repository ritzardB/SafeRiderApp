//
//  ParentTransportationScheduleView.swift
//  SafeRider
//
//  Transportation scheduling for parents
//

import SwiftUI

struct ParentTransportationScheduleView: View {
    
    @EnvironmentObject private var dataManager: DataManager
    @State private var useCustomPickupLocation = false
    @State private var useCustomDropoffLocation = false
    @State private var useCustomSchoolLocation = false
    
    @State private var customSchoolLocation = ""
    @State private var customPickupLocation = ""
    @State private var customDropoffLocation = ""
    
    // MARK: - Optional Initial Student
    
    private let initialStudent: Student?
    
    init(student: Student? = nil) {
        self.initialStudent = student
    }
    
    // MARK: - State
    
    @State private var selectedStudentID: UUID?
    
    @State private var selectedWeekdays: Set<Int> = [
        2, 3, 4, 5, 6
    ]
    
    @State private var morningPickupTime: Date =
    Self.makeTime(hour: 7, minute: 15)
    
    @State private var afternoonPickupTime: Date =
    Self.makeTime(hour: 15, minute: 0)
    
    @State private var pickupLocation = ""
    @State private var schoolLocation = ""
    @State private var homeLocation = ""
    
    @State private var isActive = true
    
    @State private var showingDeleteConfirmation = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // MARK: - Weekdays
    
    private struct Weekday: Identifiable {
        let id: Int
        let shortName: String
        let name: String
    }
    
    private let weekdays: [Weekday] = [
        Weekday(
            id: 1,
            shortName: "S",
            name: "Sunday"
        ),
        Weekday(
            id: 2,
            shortName: "M",
            name: "Monday"
        ),
        Weekday(
            id: 3,
            shortName: "T",
            name: "Tuesday"
        ),
        Weekday(
            id: 4,
            shortName: "W",
            name: "Wednesday"
        ),
        Weekday(
            id: 5,
            shortName: "T",
            name: "Thursday"
        ),
        Weekday(
            id: 6,
            shortName: "F",
            name: "Friday"
        ),
        Weekday(
            id: 7,
            shortName: "S",
            name: "Saturday"
        ),
        
    ]
    
    // MARK: - Computed Properties
    
    private var parent: Parent? {
        dataManager.currentParent
    }
    
    private var children: [Student] {
        
        guard let parent else {
            return []
        }
        
        return dataManager.students(for: parent)
    }
    
    private var selectedStudent: Student? {
        
        guard let selectedStudentID else {
            return nil
        }
        
        return children.first {
            $0.id == selectedStudentID
        }
    }
    
    /// The existing driver assigned to the student.
    ///
    /// This is read-only from the scheduling screen.
    private var assignedDriver: Driver? {
        
        guard let student = selectedStudent else {
            return nil
        }
        
        return dataManager.driver(for: student)
    }
    
    /// Existing schedule for the selected student.
    ///
    /// We intentionally include inactive schedules so they can
    /// be edited/reactivated instead of creating duplicates.
    private var existingSchedule:
    TransportationSchedule? {
        
        guard let selectedStudentID else {
            return nil
        }
        
        return dataManager.transportationSchedules.first {
            $0.studentId == selectedStudentID
        }
    }
    
    private var canSave: Bool {
        
        selectedStudent != nil
        && !selectedWeekdays.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack {
            
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()
            
            if children.isEmpty {
                
                emptyChildrenView
                
            } else {
                
                scheduleForm
            }
        }
        .navigationTitle("Transportation Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                
                Button("Save") {
                    saveSchedule()
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
        .onAppear {
            loadInitialStudent()
        }
        .onChange(of: selectedStudentID) {
            loadScheduleForSelectedStudent()
        }
        .alert(
            alertTitle,
            isPresented: $showingAlert
        ) {
            
            Button("OK") { }
            
        } message: {
            
            Text(alertMessage)
        }
        .confirmationDialog(
            "Delete Transportation Schedule?",
            isPresented:
                $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            
            Button(
                "Delete Schedule",
                role: .destructive
            ) {
                deleteSchedule()
            }
            
            Button("Cancel", role: .cancel) { }
            
        } message: {
            
            Text(
                "This will remove the transportation schedule "
                + "for the selected child. The existing driver "
                + "connection will not be changed."
            )
        }
    }
    
    private func loadScheduleForSelectedStudent() {
        guard let studentID = selectedStudentID else {
            resetScheduleFields()
            return
        }
        
        guard let schedule = dataManager.transportationSchedules.first(
            where: { $0.studentId == studentID }
        ) else {
            resetScheduleFields()
            return
        }
        
        selectedWeekdays = Set(schedule.weekdays)
        
        if let morningTime = schedule.morningPickupTime {
            morningPickupTime = morningTime
        }
        
        if let afternoonTime = schedule.afternoonPickupTime {
            afternoonPickupTime = afternoonTime
        }
        
        pickupLocation = schedule.pickupLocation
        schoolLocation = schedule.schoolLocation
        homeLocation = schedule.homeLocation
        
        isActive = schedule.isActive
        
        useCustomPickupLocation = schedule.isCustomPickupLocation
        useCustomSchoolLocation = schedule.isCustomSchoolLocation
        useCustomDropoffLocation = schedule.isCustomDropoffLocation
        
        customPickupLocation = schedule.isCustomPickupLocation
        ? schedule.pickupLocation
        : ""
        
        customSchoolLocation = schedule.isCustomSchoolLocation
        ? schedule.schoolLocation
        : ""
        
        customDropoffLocation = schedule.isCustomDropoffLocation
        ? schedule.homeLocation
        : ""
    }
    
    // MARK: - Schedule Form
    
    private var scheduleForm: some View {
        
        ScrollView {
            
            VStack(
                alignment: .leading,
                spacing: 18
            ) {
                
                childSection
                
                driverSection
                
                daysSection
                
                timeSection
                
                locationsSection
                
                statusSection
                
                if existingSchedule != nil {
                    
                    deleteSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Child Section
    
    private var childSection: some View {
        scheduleCard {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                sectionHeader(
                    title: "Select Child",
                    systemImage: "person.2.fill"
                )
                
                Text("Choose the child you want to schedule.")
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                
                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {
                    HStack(spacing: 14) {
                        ForEach(children) { child in
                            childScheduleCard(child)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if selectedStudent != nil {
                    HStack(spacing: 6) {
                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                        
                        Text("Child selected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Driver Section
    
    private var driverSection: some View {
        
        scheduleCard {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                sectionHeader(
                    title: "Assigned Driver",
                    systemImage: "car.fill"
                )
                
                if let driver = assignedDriver {
                    
                    HStack(spacing: 12) {
                        
                        ProfileAvatarView(
                            name: driver.name,
                            photoURL: driver.photoURL,
                            size: 48
                        )
                        
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            
                            Text(driver.name)
                                .font(.headline)
                                .foregroundStyle(
                                    SafeRiderTheme.primaryText
                                )
                            
                            if !driver.vehicleNumber.isEmpty {
                                
                                Text(
                                    "Vehicle: "
                                    + driver.vehicleNumber
                                )
                                .font(.subheadline)
                                .foregroundStyle(
                                    SafeRiderTheme.secondaryText
                                )
                            }
                            
                            if !driver.vehicleType.isEmpty {
                                
                                Text(driver.vehicleType)
                                    .font(.caption)
                                    .foregroundStyle(
                                        SafeRiderTheme.secondaryText
                                    )
                            }
                        }
                        
                        Spacer()
                        
                        Image(
                            systemName:
                                "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                        .font(.title3)
                    }
                    
                    Text(
                        "This driver is already connected to "
                        + "your child's SafeRider account."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    
                } else {
                    
                    HStack(
                        alignment: .top,
                        spacing: 10
                    ) {
                        
                        Image(
                            systemName:
                                "person.crop.circle.badge.exclamationmark"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )
                        .font(.title3)
                        
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            
                            Text("Driver Assignment Not Found")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(
                                    SafeRiderTheme.primaryText
                                )
                            
                            Text(
                                "A driver should already be connected "
                                + "to this child. The transportation "
                                + "schedule will not create or change "
                                + "a driver connection."
                            )
                            .font(.caption)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Child Schedule Card
    
    private func childScheduleCard(
        _ child: Student
    ) -> some View {
        let isSelected =
        selectedStudentID == child.id
        
        return Button {
            selectedStudentID = child.id
        } label: {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                HStack {
                    ProfileAvatarView(
                        name: child.name,
                        photoURL: child.photoURL,
                        size: 58
                    )
                    
                    Spacer()
                    
                    if isSelected {
                        Image(
                            systemName:
                                "checkmark.circle.fill"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )
                    }
                }
                
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(child.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )
                        .lineLimit(2)
                    
                    Text(
                        "Grade \(child.grade) • "
                        + "Section \(child.section)"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    
                    if !child.school.isEmpty {
                        Text(child.school)
                            .font(.caption2)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 0)
                
                Text(
                    isSelected
                    ? "Selected"
                    : "Tap to select"
                )
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    isSelected
                    ? SafeRiderTheme.orange
                    : SafeRiderTheme.secondaryText
                )
            }
            .padding(14)
            .frame(
                width: 220,
                height: 175,
                alignment: .topLeading
            )
            .background(
                isSelected
                ? SafeRiderTheme.orangeTint
                : SafeRiderTheme.surface
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    isSelected
                    ? SafeRiderTheme.orange
                    : Color.clear,
                    lineWidth: 2
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
            .shadow(
                color: .black.opacity(0.06),
                radius: 5,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Days Section
    
    private var daysSection: some View {
        
        scheduleCard {
            
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                
                sectionHeader(
                    title: "Transportation Days",
                    systemImage: "calendar"
                )
                
                HStack(spacing: 8) {
                    
                    ForEach(weekdays) { weekday in
                        
                        weekdayButton(
                            weekday
                        )
                    }
                }
                
                HStack(spacing: 8) {
                    
                    Button("Weekdays") {
                        
                        selectedWeekdays = [
                            2, 3, 4, 5, 6
                        ]
                    }
                    
                    Button("Every Day") {
                        
                        selectedWeekdays = [
                            1, 2, 3, 4, 5, 6, 7
                        ]
                    }
                    
                    Button("Clear") {
                        
                        selectedWeekdays.removeAll()
                    }
                }
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                
                if selectedWeekdays.isEmpty {
                    
                    Text(
                        "Select at least one transportation day."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.danger
                    )
                }
            }
        }
    }
    
    // MARK: - Weekday Button
    
    private func weekdayButton(
        _ weekday: Weekday
    ) -> some View {
        
        let isSelected =
        selectedWeekdays.contains(
            weekday.id
        )
        
        return Button {
            
            if isSelected {
                
                selectedWeekdays.remove(
                    weekday.id
                )
                
            } else {
                
                selectedWeekdays.insert(
                    weekday.id
                )
            }
            
        } label: {
            
            VStack(spacing: 4) {
                
                Text(weekday.shortName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(
                    weekday.name.prefix(3)
                )
                .font(.caption2)
            }
            .foregroundStyle(
                isSelected
                ? Color.white
                : SafeRiderTheme.primaryText
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 52
            )
            .background(
                isSelected
                ? SafeRiderTheme.orange
                : SafeRiderTheme.orangeTint
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Time Section
    
    private var timeSection: some View {
        
        scheduleCard {
            
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                
                sectionHeader(
                    title: "Pickup Times",
                    systemImage: "clock.fill"
                )
                
                DatePicker(
                    "Morning Pickup",
                    selection:
                        $morningPickupTime,
                    displayedComponents: .hourAndMinute
                )
                .tint(
                    SafeRiderTheme.orange
                )
                
                Divider()
                
                DatePicker(
                    "Afternoon Pickup",
                    selection:
                        $afternoonPickupTime,
                    displayedComponents: .hourAndMinute
                )
                .tint(
                    SafeRiderTheme.orange
                )
            }
        }
    }
    
    // MARK: - Locations Section
    
    private var locationsSection: some View {
        scheduleCard {
            VStack(
                alignment: .leading,
                spacing: 16
            ) {
                sectionHeader(
                    title: "Transportation Locations",
                    systemImage: "mappin.and.ellipse"
                )
                
                // MARK: Morning Pickup
                
                locationSelectionCard(
                    title: "Morning Pickup",
                    icon: "location.fill",
                    defaultTitle: "Home Address",
                    defaultAddress: selectedStudent?.homeAddress ?? "",
                    useCustomLocation: $useCustomPickupLocation,
                    customLocation: $customPickupLocation
                )
                
                Divider()
                
                // MARK: School
                
                locationSelectionCard(
                    title: "School",
                    icon: "building.2.fill",
                    defaultTitle: selectedStudent?.school ?? "School",
                    defaultAddress: selectedStudent?.schoolAddress ?? "",
                    useCustomLocation: $useCustomSchoolLocation,
                    customLocation: $customSchoolLocation
                )
                Divider()
                
                // MARK: Afternoon Drop-off
                
                locationSelectionCard(
                    title: "Afternoon Drop-off",
                    icon: "house.fill",
                    defaultTitle: "Home Address",
                    defaultAddress: selectedStudent?.homeAddress ?? "",
                    useCustomLocation: $useCustomDropoffLocation,
                    customLocation: $customDropoffLocation
                )
            }
        }
    }
    
    // MARK: - Location Field
    
    private func locationField(
        title: String,
        icon: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            
            Label(
                title,
                systemImage: icon
            )
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
            
            TextField(
                placeholder,
                text: text,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.plain)
            .padding(12)
            .background(
                SafeRiderTheme.orangeTint
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )
        }
    }
    
    // MARK: - Location Selection Card
    
    private func locationSelectionCard(
        title: String,
        icon: String,
        defaultTitle: String,
        defaultAddress: String,
        useCustomLocation: Binding<Bool>,
        customLocation: Binding<String>
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Label(
                title,
                systemImage: icon
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
            
            Picker(
                "Location",
                selection: useCustomLocation
            ) {
                Text(
                    defaultTitle
                )
                .tag(false)
                
                Text("Custom Location")
                    .tag(true)
            }
            .pickerStyle(.segmented)
            .tint(
                SafeRiderTheme.orange
            )
            
            if useCustomLocation.wrappedValue {
                TextField(
                    "Enter custom transportation address",
                    text: customLocation,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    SafeRiderTheme.orangeTint
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )
            } else {
                addressPreview(
                    title: defaultTitle,
                    address: defaultAddress
                )
            }
        }
    }
    
    // MARK: - Location Display Card
    
    private func locationDisplayCard(
        title: String,
        icon: String,
        locationName: String,
        address: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Label(
                title,
                systemImage: icon
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
            
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(locationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
                
                addressPreview(
                    title: "School Address",
                    address: address
                )
            }
        }
    }
    
    // MARK: - Address Preview
    
    private func addressPreview(
        title: String,
        address: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 8
        ) {
            Image(
                systemName: "mappin.circle.fill"
            )
            .foregroundStyle(
                SafeRiderTheme.orange
            )
            
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                
                if address
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                        .isEmpty
                {
                    Text("Address not configured")
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.danger
                        )
                } else {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )
                }
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        
        scheduleCard {
            
            Toggle(
                isOn: $isActive
            ) {
                
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    
                    Text("Transportation Active")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )
                    
                    Text(
                        "Turn this off temporarily without "
                        + "deleting the schedule."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }
            }
            .tint(
                SafeRiderTheme.orange
            )
        }
    }
    
    // MARK: - Delete Section
    
    private var deleteSection: some View {
        
        Button {
            
            showingDeleteConfirmation = true
            
        } label: {
            
            Label(
                "Delete Transportation Schedule",
                systemImage: "trash"
            )
            .frame(
                maxWidth: .infinity
            )
        }
        .buttonStyle(
            .bordered
        )
        .tint(
            SafeRiderTheme.danger
        )
    }
    
    // MARK: - Empty Children
    
    private var emptyChildrenView: some View {
        
        ContentUnavailableView(
            "No Children",
            systemImage: "person.2.slash",
            description: Text(
                "Add a child to your parent account "
                + "before creating a transportation schedule."
            )
        )
    }
    
    // MARK: - Card
    
    @ViewBuilder
    private func scheduleCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        
        content()
            .padding()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
            .shadow(
                color: .black.opacity(0.06),
                radius: 5,
                y: 2
            )
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(
        title: String,
        systemImage: String
    ) -> some View {
        
        Label(
            title,
            systemImage: systemImage
        )
        .font(.headline)
        .foregroundStyle(
            SafeRiderTheme.primaryText
        )
    }
    
    // MARK: - Load Initial Student
    
    private func loadInitialStudent() {
        
        if let initialStudent {
            
            if children.contains(
                where: { $0.id == initialStudent.id }
            ) {
                
                selectedStudentID =
                initialStudent.id
                
                loadSchedule(
                    for: initialStudent.id
                )
                
                return
            }
        }
        
        guard let firstChild = children.first else {
            return
        }
        
        selectedStudentID =
        firstChild.id
        
        loadSchedule(
            for: firstChild.id
        )
    }
    
    // MARK: - Load Selected Schedule
    
    private func loadSchedule(
        for studentID: UUID
    ) {
        
        guard let schedule =
                dataManager.transportationSchedules.first(
                    where: {
                        $0.studentId == studentID
                    }
                )
        else {
            
            resetScheduleFields()
            return
        }
        
        selectedWeekdays =
        Set(schedule.weekdays)
        
        morningPickupTime =
        schedule.morningPickupTime
        ?? Self.makeTime(
            hour: 7,
            minute: 15
        )
        
        afternoonPickupTime =
        schedule.afternoonPickupTime
        ?? Self.makeTime(
            hour: 15,
            minute: 0
        )
        
        pickupLocation =
        schedule.pickupLocation
        
        schoolLocation =
        schedule.schoolLocation
        
        homeLocation =
        schedule.homeLocation
        
        isActive =
        schedule.isActive
    }
    
    // MARK: - Reset Fields
    
    private func resetScheduleFields() {
        
        selectedWeekdays = [
            2, 3, 4, 5, 6
        ]
        
        morningPickupTime =
        Self.makeTime(
            hour: 7,
            minute: 15
        )
        
        afternoonPickupTime =
        Self.makeTime(
            hour: 15,
            minute: 0
        )
        
        pickupLocation = ""
        schoolLocation = ""
        homeLocation = ""
        
        // Reset location selections
        useCustomPickupLocation = false
        useCustomSchoolLocation = false
        useCustomDropoffLocation = false
        
        customPickupLocation = ""
        customSchoolLocation = ""
        customDropoffLocation = ""
        
        isActive = true
    }
    
    // MARK: - Save
    
    private func saveSchedule() {
        
        guard let parent else {
            
            showError(
                title: "Parent Profile Missing",
                message:
                    "Your parent profile could not be loaded."
            )
            
            return
        }
        
        guard let student = selectedStudent else {
            
            showError(
                title: "Select a Child",
                message:
                    "Please select a child before saving "
                + "the transportation schedule."
            )
            
            return
        }
        
        guard !selectedWeekdays.isEmpty else {
            
            showError(
                title: "Select Transportation Days",
                message:
                    "Please select at least one day."
            )
            
            return
        }
        
        // IMPORTANT:
        //
        // The driver is NOT assigned here.
        //
        // We use the student's existing driverId,
        // which was established earlier through the
        // SafeRider driver connection flow.
        
        guard let driverID = student.driverId else {
            
            showError(
                title: "Driver Assignment Missing",
                message:
                    "\(student.name) does not currently "
                + "have an assigned driver. "
                + "Please verify the existing driver "
                + "connection before creating the schedule."
            )
            
            return
        }
        
        let now = Date()
        
        let scheduleID =
        existingSchedule?.id ?? UUID()
        
        let createdAt =
        existingSchedule?.createdAt ?? now
        
        let savedPickupLocation =
        useCustomPickupLocation
        ? customPickupLocation.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        : student.homeAddress.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let savedSchoolLocation =
        useCustomSchoolLocation
        ? customSchoolLocation.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        : student.schoolAddress.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        let savedDropoffLocation =
        useCustomDropoffLocation
        ? customDropoffLocation.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        : student.homeAddress.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        print("🕐 Morning before save:", morningPickupTime)
        print("🕒 Afternoon before save:", afternoonPickupTime)
        print("📅 Selected weekdays before save:", selectedWeekdays.sorted())
        
        let schedule =
        TransportationSchedule(
            id: scheduleID,
            parentId: parent.id,
            studentId: student.id,
            driverId: driverID,
            weekdays: selectedWeekdays.sorted(),
            morningPickupTime: morningPickupTime,
            afternoonPickupTime: afternoonPickupTime,
            pickupLocation: savedPickupLocation,
            schoolLocation: savedSchoolLocation,
            homeLocation: savedDropoffLocation,
            isCustomPickupLocation: useCustomPickupLocation,
            isCustomSchoolLocation: useCustomSchoolLocation,
            isCustomDropoffLocation: useCustomDropoffLocation,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: now

        )
      
        
        // IMPORTANT:
        //
        // This writes ONLY to transportationSchedules.
        //
        // It does NOT modify:
        // - driverConnections
        // - students.driverId
        // - students.driverAuthUID
        
        dataManager.saveTransportationSchedule(
            schedule
        )
        
        showSuccess(
            title: existingSchedule == nil
            ? "Schedule Saved"
            : "Schedule Updated",
            message:
                "Transportation schedule for "
            + "\(student.name) has been saved."
        )
    }
    
    // MARK: - Delete
    
    private func deleteSchedule() {
        
        guard let schedule =
                existingSchedule
        else {
            return
        }
        
        dataManager.deleteTransportationSchedule(
            schedule
        )
        
        resetScheduleFields()
        
        showSuccess(
            title: "Schedule Deleted",
            message:
                "The transportation schedule was deleted. "
            + "The existing driver connection remains unchanged."
        )
    }
    
    // MARK: - Alerts
    
    private func showError(
        title: String,
        message: String
    ) {
        
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func showSuccess(
        title: String,
        message: String
    ) {
        
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Time Helper
    
    private static func makeTime(
        hour: Int,
        minute: Int
    ) -> Date {
        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: Date()
        )
        
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return Calendar.current.date(
            from: components
        ) ?? Date()
    }
}
