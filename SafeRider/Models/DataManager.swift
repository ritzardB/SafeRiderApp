//
//  DataManager.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 07/09/2026.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class DataManager: ObservableObject {
    
    // MARK: - Published Data
    
    @Published private(set) var parents: [Parent] = []
    @Published private(set) var drivers: [Driver] = []
    @Published private(set) var students: [Student] = []
    @Published private(set) var rides: [Ride] = []
    @Published private(set) var payments: [Payment] = []
    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var systemLogs: [Log] = []
    @Published private(set) var transportationSchedules: [TransportationSchedule] = []
    
    @Published private(set) var currentParent: Parent?
    @Published private(set) var currentDriver: Driver?
    
    @Published var errorMessage: String?
    @Published private(set) var isLoading = true
    
    // MARK: - Firebase
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    
    private var currentUID: String?
    private var currentRole: UserRole?
    
    // MARK: - Init
    
    init() {
        // Firebase listeners are started after authentication
        // is known through syncAuthenticatedUser().
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    // MARK: - Session
    
    func syncAuthenticatedUser(
        uid: String?,
        email: String?,
        role: UserRole?
    ) {
        currentUID = uid
        currentRole = role
        
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        currentParent = nil
        currentDriver = nil
        
        parents = []
        drivers = []
        students = []
        rides = []
        payments = []
        expenses = []
        systemLogs = []
        transportationSchedules = []
        
        guard let uid, let role else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                switch role {
                case .parent:
                    currentParent = try await ensureParentProfile(
                        uid: uid,
                        email: email ?? ""
                    )
                    
                    startListeners()
                    
                case .driver:
                    currentDriver = try await ensureDriverProfile(
                        uid: uid,
                        email: email ?? ""
                    )
                    
                    startListeners()
                    
                case .admin:
                    startListeners()
                }
                
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    func setCurrentUser(
        uid: String?,
        role: UserRole?
    ) {
        syncAuthenticatedUser(
            uid: uid,
            email: nil,
            role: role
        )
    }
    
    // MARK: - Notifications
    
    func driverOnTheWay(
        student: Student,
        driver: Driver
    ) {
        guard let parentId = student.parentId else {
            errorMessage = "This student is not linked to a parent."
            return
        }
        
        Task {
            do {
                let snapshot = try await db
                    .collection("parents")
                    .document(parentId.uuidString)
                    .getDocument()
                
                guard
                    let parentData = snapshot.data(),
                    let parentAuthUID = parentData["authUID"] as? String,
                    !parentAuthUID.isEmpty
                else {
                    errorMessage =
                    "The student's parent account could not be found."
                    return
                }
                
                let notificationId = UUID().uuidString
                
                let driverName = driver.name.isEmpty
                ? driver.email
                : driver.name
                
                let data: [String: Any] = [
                    "id": notificationId,
                    "recipientUID": parentAuthUID,
                    "title": "Driver On The Way",
                    "message":
                        "\(driverName) is on the way to pick up "
                    + "\(student.name).",
                    "studentId": student.id.uuidString,
                    "studentName": student.name,
                    "driverId": driver.id.uuidString,
                    "driverName": driverName,
                    "type": "driverEnRoute",
                    "read": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                try await db
                    .collection("notifications")
                    .document(notificationId)
                    .setData(data)
                
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Profile Creation
    
    private func ensureParentProfile(
        uid: String,
        email: String
    ) async throws -> Parent {
        
        if let existing = parents.first(
            where: { $0.authUID == uid }
        ) {
            return existing
        }
        
        let snapshot = try await db
            .collection("parents")
            .whereField("authUID", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments()
        
        if
            let document = snapshot.documents.first,
            let profile = parent(from: document.data())
        {
            return profile
        }
        
        let profile = Parent(
            authUID: uid,
            email: email
        )
        
        try await db
            .collection("parents")
            .document(profile.id.uuidString)
            .setData(parentData(profile))
        
        return profile
    }
    
    private func ensureDriverProfile(
        uid: String,
        email: String
    ) async throws -> Driver {
        
        if let existing = drivers.first(
            where: { $0.authUID == uid }
        ) {
            return existing
        }
        
        let snapshot = try await db
            .collection("drivers")
            .whereField("authUID", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments()
        
        if
            let document = snapshot.documents.first,
            let profile = driver(from: document.data())
        {
            return profile
        }
        
        let profile = Driver(
            authUID: uid,
            name: "",
            licenseNumber: "",
            vehicleNumber: "",
            vehicleType: "",
            email: email,
            phoneNumber: ""
        )
        
        try await db
            .collection("drivers")
            .document(profile.id.uuidString)
            .setData(driverData(profile))
        
        return profile
    }
    
    // MARK: - Firestore Listeners
    
    private func startListeners() {
        guard
            let role = currentRole,
            let uid = currentUID
        else {
            return
        }
        
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        // MARK: Admin
        
        if role == .admin {
            addCollectionListener("parents") { documents in
                self.parents = documents.compactMap {
                    self.parent(from: $0.data())
                }
                
                self.refreshCurrentProfile()
            }
            
            addCollectionListener("drivers") { documents in
                self.drivers = documents.compactMap {
                    self.driver(from: $0.data())
                }
                
                self.refreshCurrentProfile()
            }
            
            addCollectionListener("students") { documents in
                self.students = documents.compactMap {
                    self.student(from: $0.data())
                }
            }
            
            addCollectionListener("rides") { documents in
                self.rides = documents.compactMap {
                    self.ride(from: $0.data())
                }
            }
            
            addCollectionListener("payments") { documents in
                self.payments = documents.compactMap {
                    self.payment(from: $0.data())
                }
            }
            
            addCollectionListener("expenses") { documents in
                self.expenses = documents.compactMap {
                    self.expense(from: $0.data())
                }
            }
            
            addCollectionListener("systemLogs") { documents in
                self.systemLogs = documents.compactMap {
                    self.log(from: $0.data())
                }
            }
            
            addCollectionListener("transportationSchedules") { documents in
                self.transportationSchedules = documents.compactMap {
                    self.transportationSchedule(
                        from: $0.data()
                    )
                }
            }
            
            return
        }
        
        // MARK: Role-specific Listeners
        
        switch role {
            
        case .parent:
            
            // Parent profile
            addQueryListener(
                db.collection("parents")
                    .whereField(
                        "authUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.parents = documents.compactMap {
                    self.parent(from: $0.data())
                }
                
                self.refreshCurrentProfile()
                
                // Start parent-specific listeners only after
                // currentParent is available.
                self.startParentPaymentListener()
                self.startParentScheduleListener()
            }
            
            // Children
            addQueryListener(
                db.collection("students")
                    .whereField(
                        "parentAuthUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.students = documents.compactMap {
                    self.student(from: $0.data())
                }
            }
            
            // Rides
            addQueryListener(
                db.collection("rides")
                    .whereField(
                        "parentAuthUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.rides = documents.compactMap {
                    self.ride(from: $0.data())
                }
            }
            
        case .driver:
            
            // Driver profile
            addQueryListener(
                db.collection("drivers")
                    .whereField(
                        "authUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.drivers = documents.compactMap {
                    self.driver(from: $0.data())
                }
                
                self.refreshCurrentProfile()
            }
            
            // Assigned students
            addQueryListener(
                db.collection("students")
                    .whereField(
                        "driverAuthUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                let assignedStudents = documents.compactMap {
                    self.student(from: $0.data())
                }
                
                self.students = assignedStudents
                
                Task {
                    await self.loadParents(
                        for: assignedStudents
                    )
                }
            }
            
            // Expenses
            addQueryListener(
                db.collection("expenses")
                    .whereField(
                        "driverAuthUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.expenses = documents.compactMap {
                    self.expense(from: $0.data())
                }
            }
            
            // Payments
            addQueryListener(
                db.collection("payments")
                    .whereField(
                        "driverAuthUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.payments = documents.compactMap {
                    self.payment(from: $0.data())
                }
            }
            
            // Rides
            addQueryListener(
                db.collection("rides")
                    .whereField(
                        "driverAuthUID",
                        isEqualTo: uid
                    )
            ) { documents in
                
                self.rides = documents.compactMap {
                    self.ride(from: $0.data())
                }
            }
            
            // Transportation schedules for assigned students
            addQueryListener(
                db.collection("transportationSchedules")
            ) { documents in
                
                let allSchedules = documents.compactMap {
                    self.transportationSchedule(
                        from: $0.data()
                    )
                }
                
                let assignedIDs = Set(
                    self.students.map(\.id)
                )
                
                self.transportationSchedules =
                allSchedules.filter {
                    assignedIDs.contains(
                        $0.studentId
                    )
                }
            }
            
        case .admin:
            break
        }
    }
    
    private func addCollectionListener(
        _ collection: String,
        apply: @escaping (
            [QueryDocumentSnapshot]
        ) -> Void
    ) {
        addQueryListener(
            db.collection(collection),
            apply: apply
        )
    }
    
    private func addQueryListener(
        _ query: Query,
        apply: @escaping (
            [QueryDocumentSnapshot]
        ) -> Void
    ) {
        listeners.append(
            query.addSnapshotListener {
                [weak self] snapshot, error in
                
                Task { @MainActor in
                    guard let self else {
                        return
                    }
                    
                    if let error {
                        self.errorMessage =
                        error.localizedDescription
                        return
                    }
                    
                    apply(
                        snapshot?.documents ?? []
                    )
                    
                    self.errorMessage = nil
                }
            }
        )
    }
    
    private func refreshCurrentProfile() {
        guard
            let uid = currentUID
        else {
            return
        }
        
        switch currentRole {
            
        case .parent:
            currentParent = parents.first {
                $0.authUID == uid
            }
            
        case .driver:
            currentDriver = drivers.first {
                $0.authUID == uid
            }
            
        case .admin, .none:
            break
        }
    }
    
    // MARK: - Parent Payment Listener
    
    private func startParentPaymentListener() {
        guard
            let parentId = currentParent?.id
        else {
            return
        }
        
        addQueryListener(
            db.collection("payments")
                .whereField(
                    "parentId",
                    isEqualTo: parentId.uuidString
                )
        ) { documents in
            
            self.payments = documents.compactMap {
                self.payment(from: $0.data())
            }
        }
    }
    
    // MARK: - Parent Schedule Listener
    
    private func startParentScheduleListener() {
        guard
            let parentId = currentParent?.id
        else {
            return
        }
        
        addQueryListener(
            db.collection(
                "transportationSchedules"
            )
            .whereField(
                "parentId",
                isEqualTo: parentId.uuidString
            )
        ) { documents in
            
            self.transportationSchedules =
            documents.compactMap {
                self.transportationSchedule(
                    from: $0.data()
                )
            }
        }
    }
    
    // MARK: - Parent Mutations
    
    func addParent(
        _ parent: Parent
    ) {
        write(
            "parents",
            id: parent.id.uuidString,
            data: parentData(parent)
        )
    }
    
    func updateParent(
        _ parent: Parent
    ) {
        write(
            "parents",
            id: parent.id.uuidString,
            data: parentData(parent),
            merge: true
        )
        
        if currentParent?.id == parent.id {
            currentParent = parent
        }
    }
    
    func deleteParents(
        at offsets: IndexSet
    ) {
        let ids = offsets.compactMap { index in
            parents.indices.contains(index)
            ? parents[index].id.uuidString
            : nil
        }
        
        ids.forEach {
            delete(
                "parents",
                id: $0
            )
        }
    }
    
    // MARK: - Driver Mutations
    
    func addDriver(
        _ driver: Driver
    ) {
        write(
            "drivers",
            id: driver.id.uuidString,
            data: driverData(driver)
        )
    }
    
    func updateDriver(
        _ driver: Driver
    ) {
        write(
            "drivers",
            id: driver.id.uuidString,
            data: driverData(driver),
            merge: true
        )
        
        if currentDriver?.id == driver.id {
            currentDriver = driver
        }
    }
    
    func deleteDrivers(
        at offsets: IndexSet
    ) {
        let ids = offsets.compactMap { index in
            drivers.indices.contains(index)
            ? drivers[index].id.uuidString
            : nil
        }
        
        ids.forEach {
            delete(
                "drivers",
                id: $0
            )
        }
    }
    
    // MARK: - Student Mutations
    
    func addStudent(
        _ student: Student,
        driverAuthUID: String? = nil
    ) {
        Task {
            var data = studentData(student)
            
            // Parent Firebase UID
            if let parentId = student.parentId {
                if
                    let parent = parents.first(
                        where: { $0.id == parentId }
                    ),
                    let authUID = parent.authUID,
                    !authUID.isEmpty
                {
                    data["parentAuthUID"] = authUID
                }
            }
            
            // Driver Firebase UID
            if
                let driverAuthUID,
                !driverAuthUID.isEmpty
            {
                data["driverAuthUID"] =
                driverAuthUID
            }
            
            do {
                try await db
                    .collection("students")
                    .document(student.id.uuidString)
                    .setData(data)
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    func updateStudent(
        _ student: Student,
        driverAuthUID: String? = nil
    ) {
        Task {
            var data = studentData(student)
            
            // Parent Firebase UID
            if let parentId = student.parentId {
                if
                    let parent = parents.first(
                        where: { $0.id == parentId }
                    ),
                    let authUID = parent.authUID,
                    !authUID.isEmpty
                {
                    data["parentAuthUID"] = authUID
                }
            }
            
            // Driver Firebase UID
            if
                let driverAuthUID,
                !driverAuthUID.isEmpty
            {
                data["driverAuthUID"] =
                driverAuthUID
            }
            
            do {
                try await db
                    .collection("students")
                    .document(student.id.uuidString)
                    .setData(
                        data,
                        merge: true
                    )
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    func updateStudentPhotoURL(
        studentId: UUID,
        photoURL: String
    ) {
        Task {
            do {
                try await db
                    .collection("students")
                    .document(studentId.uuidString)
                    .updateData([
                        "photoURL": photoURL
                    ])
                
                if let index = students.firstIndex(
                    where: { $0.id == studentId }
                ) {
                    students[index].photoURL =
                    photoURL
                }
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    func deleteStudents(
        at offsets: IndexSet
    ) {
        let ids = offsets.compactMap { index in
            students.indices.contains(index)
            ? students[index].id.uuidString
            : nil
        }
        
        ids.forEach {
            delete(
                "students",
                id: $0
            )
        }
    }
    
    // MARK: - Ride Mutations
    
    func addRide(
        _ ride: Ride
    ) {
        write(
            "rides",
            id: ride.id.uuidString,
            data: rideData(ride)
        )
    }
    
    func updateTodayRide(
        studentId: UUID,
        driverId: UUID,
        status: RideStatus
    ) {
        if let existing = rides.first(
            where: {
                $0.studentId == studentId
                && $0.driverId == driverId
                && Calendar.current.isDate(
                    $0.date,
                    inSameDayAs: Date()
                )
            }
        ) {
            var updated = existing
            updated.status = status
            
            if status == .pickedUp {
                updated.pickupTime = Date()
            }
            
            if status == .arrivedHome {
                updated.dropoffTime = Date()
            }
            
            updateRide(updated)
        } else {
            addRide(
                Ride(
                    studentId: studentId,
                    driverId: driverId,
                    date: Date(),
                    status: status
                )
            )
        }
    }
    
    func updateRide(
        _ ride: Ride
    ) {
        write(
            "rides",
            id: ride.id.uuidString,
            data: rideData(ride),
            merge: true
        )
    }
    
    // MARK: - Payment Mutations
    
    func addPayment(
        _ payment: Payment
    ) {
        Task {
            var data = paymentData(payment)
            
            switch currentRole {
                
            case .parent:
                guard
                    let parent = currentParent
                else {
                    errorMessage =
                    "Parent profile is not available."
                    return
                }
                
                data["parentId"] =
                parent.id.uuidString
                
                guard
                    let parentAuthUID =
                        parent.authUID,
                    !parentAuthUID.isEmpty
                else {
                    errorMessage =
                    "Parent account is not linked to Firebase."
                    return
                }
                
                data["parentAuthUID"] =
                parentAuthUID
                
            case .driver:
                guard
                    let driver = currentDriver
                else {
                    errorMessage =
                    "Driver profile is not available."
                    return
                }
                
                data["driverId"] =
                driver.id.uuidString
                
                guard
                    let driverAuthUID =
                        driver.authUID,
                    !driverAuthUID.isEmpty
                else {
                    errorMessage =
                    "Driver account is not linked to Firebase."
                    return
                }
                
                data["driverAuthUID"] =
                driverAuthUID
                
            case .admin:
                break
                
            case .none:
                errorMessage =
                "No authenticated SafeRider role is available."
                return
            }
            
            do {
                try await db
                    .collection("payments")
                    .document(payment.id.uuidString)
                    .setData(data)
                
                // Update local state immediately.
                if let index = payments.firstIndex(
                    where: { $0.id == payment.id }
                ) {
                    payments[index] = payment
                } else {
                    payments.append(payment)
                }
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    func deletePayment(
        _ payment: Payment
    ) {
        Task {
            do {
                try await db
                    .collection("payments")
                    .document(payment.id.uuidString)
                    .delete()
                
                payments.removeAll {
                    $0.id == payment.id
                }
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    // MARK: - Expense Mutations
    
    func addExpense(
        _ expense: Expense
    ) {
        var expense = expense
        
        if let driver = currentDriver {
            expense.driverId = driver.id
        }
        
        write(
            "expenses",
            id: expense.id.uuidString,
            data: expenseData(expense)
        )
    }
    
    // MARK: - Transportation Schedule
    
    func saveTransportationSchedule(
        _ schedule: TransportationSchedule
    ) {
        var data: [String: Any] = [
            "id": schedule.id.uuidString,
            "parentId": schedule.parentId.uuidString,
            "driverId": schedule.driverId.uuidString,
            "studentId": schedule.studentId.uuidString,
            "weekdays": schedule.weekdays,
            "pickupLocation": schedule.pickupLocation,
            "schoolLocation": schedule.schoolLocation,
            "homeLocation": schedule.homeLocation,
            "isActive": schedule.isActive,
            "createdAt": Timestamp(
                date: schedule.createdAt
            ),
            "updatedAt": Timestamp(
                date: Date()
            )
        ]
        
        if let morningPickupTime =
            schedule.morningPickupTime
        {
            data["morningPickupTime"] =
            Timestamp(date: morningPickupTime)
        }
        
        if let afternoonPickupTime =
            schedule.afternoonPickupTime
        {
            data["afternoonPickupTime"] =
            Timestamp(date: afternoonPickupTime)
        }
        
        write(
            "transportationSchedules",
            id: schedule.id.uuidString,
            data: data,
            merge: true
        )
    }
    
    func deleteTransportationSchedule(
        _ schedule: TransportationSchedule
    ) {
        delete(
            "transportationSchedules",
            id: schedule.id.uuidString
        )
    }
    
    // MARK: - Queries
    
    func students(
        for parent: Parent
    ) -> [Student] {
        students.filter {
            $0.parentId == parent.id
        }
    }
    
    func students(
        for driver: Driver
    ) -> [Student] {
        students.filter {
            $0.driverId == driver.id
        }
    }
    
    func parent(
        for student: Student
    ) -> Parent? {
        guard
            let parentId = student.parentId
        else {
            return nil
        }
        
        return parents.first {
            $0.id == parentId
        }
    }
    
    func driver(
        for student: Student
    ) -> Driver? {
        guard
            let driverId = student.driverId
        else {
            return nil
        }
        
        return drivers.first {
            $0.id == driverId
        }
    }
    
    func student(
        for ride: Ride
    ) -> Student? {
        students.first {
            $0.id == ride.studentId
        }
    }
    
    func driver(
        for ride: Ride
    ) -> Driver? {
        drivers.first {
            $0.id == ride.driverId
        }
    }
    
    func transportationSchedule(
        for student: Student
    ) -> TransportationSchedule? {
        transportationSchedules.first {
            $0.studentId == student.id
            && $0.isActive
        }
    }
    
    // MARK: - Firestore Writes
    
    private func write(
        _ collection: String,
        id: String,
        data: [String: Any],
        merge: Bool = false
    ) {
        Task {
            do {
                try await db
                    .collection(collection)
                    .document(id)
                    .setData(
                        data,
                        merge: merge
                    )
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    private func delete(
        _ collection: String,
        id: String
    ) {
        Task {
            do {
                try await db
                    .collection(collection)
                    .document(id)
                    .delete()
                
                errorMessage = nil
            } catch {
                errorMessage =
                error.localizedDescription
            }
        }
    }
    
    // MARK: - Load Parents
    
    private func loadParents(
        for students: [Student]
    ) async {
        var loadedParents: [Parent] = []

        let parentIDs = Set(
            students.compactMap { $0.parentId }
        )

        for parentID in parentIDs {
            do {
                let snapshot = try await db
                    .collection("parents")
                    .document(parentID.uuidString)
                    .getDocument()

                guard let data = snapshot.data() else {
                    continue
                }

                guard let parent = parent(from: data) else {
                    continue
                }

                loadedParents.append(parent)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        parents = loadedParents
    }
    
    // MARK: - Firestore Mapping Helpers
    
    private func string(
        _ data: [String: Any],
        _ key: String
    ) -> String? {
        data[key] as? String
    }
    
    private func uuid(
        _ data: [String: Any],
        _ key: String
    ) -> UUID? {
        string(
            data,
            key
        ).flatMap(
            UUID.init(uuidString:)
        )
    }
    
    private func date(
        _ data: [String: Any],
        _ key: String
    ) -> Date? {
        (data[key] as? Timestamp)?.dateValue()
    }
    
    private func date(
        _ data: [String: Any],
        _ key: String,
        fallback: Date
    ) -> Date {
        date(
            data,
            key
        ) ?? fallback
    }
    
    // MARK: - Parent Mapping
    
    private func parentData(
        _ p: Parent
    ) -> [String: Any] {
        var data: [String: Any] = [
            "id": p.id.uuidString,
            "motherName": p.motherName,
            "fatherName": p.fatherName,
            "email": p.email,
            "contactNumber": p.contactNumber,
            "updatedAt":
                FieldValue.serverTimestamp()
        ]
        
        if let authUID = p.authUID {
            data["authUID"] = authUID
        }
        
        if let photoURL = p.photoURL {
            data["photoURL"] = photoURL
        }
        
        if let bannerURL = p.bannerURL {
            data["bannerURL"] = bannerURL
        }
        
        return data
    }
    
    private func parent(
        from d: [String: Any]
    ) -> Parent? {
        guard
            let id = uuid(d, "id")
        else {
            return nil
        }
        
        return Parent(
            id: id,
            authUID: string(
                d,
                "authUID"
            ),
            motherName: string(
                d,
                "motherName"
            ) ?? "",
            fatherName: string(
                d,
                "fatherName"
            ) ?? "",
            email: string(
                d,
                "email"
            ) ?? "",
            contactNumber: string(
                d,
                "contactNumber"
            ) ?? "",
            photoURL: string(
                d,
                "photoURL"
            ),
            bannerURL: string(
                d,
                "bannerURL"
            )
        )
    }
    
    // MARK: - Driver Mapping
    
    private func driverData(
        _ d: Driver
    ) -> [String: Any] {
        var data: [String: Any] = [
            "id": d.id.uuidString,
            "name": d.name,
            "licenseNumber":
                d.licenseNumber,
            "vehicleNumber":
                d.vehicleNumber,
            "vehicleType":
                d.vehicleType,
            "email": d.email,
            "phoneNumber":
                d.phoneNumber,
            "updatedAt":
                FieldValue.serverTimestamp()
        ]
        
        if let authUID = d.authUID {
            data["authUID"] = authUID
        }
        
        if let photoURL = d.photoURL {
            data["photoURL"] = photoURL
        }
        
        return data
    }
    
    private func driver(
        from d: [String: Any]
    ) -> Driver? {
        guard
            let id = uuid(d, "id")
        else {
            return nil
        }
        
        return Driver(
            id: id,
            authUID: string(
                d,
                "authUID"
            ),
            name: string(
                d,
                "name"
            ) ?? "",
            licenseNumber: string(
                d,
                "licenseNumber"
            ) ?? "",
            vehicleNumber: string(
                d,
                "vehicleNumber"
            ) ?? "",
            vehicleType: string(
                d,
                "vehicleType"
            ) ?? "",
            email: string(
                d,
                "email"
            ) ?? "",
            phoneNumber: string(
                d,
                "phoneNumber"
            ) ?? "",
            photoURL: string(
                d,
                "photoURL"
            )
        )
    }
    
    // MARK: - Student Mapping
    
    private func studentData(
        _ s: Student
    ) -> [String: Any] {
        var data: [String: Any] = [
            "id": s.id.uuidString,
            "name": s.name,
            "grade": s.grade,
            "section": s.section,
            "teacherName":
                s.teacherName,
            "teacherPhone":
                s.teacherPhone,
            "school": s.school,
            "updatedAt":
                FieldValue.serverTimestamp()
        ]
        
        if let parentId = s.parentId {
            data["parentId"] =
            parentId.uuidString
            
            if let authUID =
                parents.first(
                    where: {
                        $0.id == parentId
                    }
                )?.authUID
            {
                data["parentAuthUID"] =
                authUID
            }
        }
        
        if let driverId = s.driverId {
            data["driverId"] =
            driverId.uuidString
            
            if let authUID =
                drivers.first(
                    where: {
                        $0.id == driverId
                    }
                )?.authUID
            {
                data["driverAuthUID"] =
                authUID
            }
        }
        
        if let photoURL = s.photoURL,
           !photoURL.isEmpty
        {
            data["photoURL"] =
            photoURL
        }
        
        return data
    }
    
    private func student(
        from data: [String: Any]
    ) -> Student? {
        
        guard
            let idString =
                data["id"] as? String,
            let id =
                UUID(
                    uuidString: idString
                ),
            let name =
                data["name"] as? String,
            let grade =
                data["grade"] as? String,
            let section =
                data["section"] as? String,
            let teacherName =
                data["teacherName"] as? String,
            let teacherPhone =
                data["teacherPhone"] as? String,
            let school =
                data["school"] as? String
        else {
            return nil
        }
        
        return Student(
            id: id,
            name: name,
            grade: grade,
            section: section,
            teacherName: teacherName,
            teacherPhone: teacherPhone,
            parentId: uuid(
                data,
                "parentId"
            ),
            driverId: uuid(
                data,
                "driverId"
            ),
            school: school,
            photoURL: string(
                data,
                "photoURL"
            )
        )
    }
    
    // MARK: - Ride Mapping
    
    private func rideData(
        _ r: Ride
    ) -> [String: Any] {
        
        var data: [String: Any] = [
            "id": r.id.uuidString,
            "studentId":
                r.studentId.uuidString,
            "driverId":
                r.driverId.uuidString,
            "date":
                Timestamp(date: r.date),
            "status":
                r.status.rawValue,
            "pickupLocation":
                r.pickupLocation,
            "dropoffLocation":
                r.dropoffLocation,
            "notes":
                r.notes,
            "updatedAt":
                FieldValue.serverTimestamp()
        ]
        
        if let pickupTime = r.pickupTime {
            data["pickupTime"] =
            Timestamp(date: pickupTime)
        }
        
        if let dropoffTime = r.dropoffTime {
            data["dropoffTime"] =
            Timestamp(date: dropoffTime)
        }
        
        if let parentId = r.parentId {
            
            data["parentId"] =
            parentId.uuidString
            
            if let authUID =
                parents.first(
                    where: {
                        $0.id == parentId
                    }
                )?.authUID
            {
                data["parentAuthUID"] =
                authUID
            }
            
        } else if let parentId =
                    students.first(
                        where: {
                            $0.id == r.studentId
                        }
                    )?.parentId
        {
            data["parentId"] =
            parentId.uuidString
            
            if let authUID =
                parents.first(
                    where: {
                        $0.id == parentId
                    }
                )?.authUID
            {
                data["parentAuthUID"] =
                authUID
            }
        }
        
        if let authUID =
            drivers.first(
                where: {
                    $0.id == r.driverId
                }
            )?.authUID
        {
            data["driverAuthUID"] =
            authUID
        }
        
        return data
    }
    
    private func ride(
        from d: [String: Any]
    ) -> Ride? {
        
        guard
            let id = uuid(
                d,
                "id"
            ),
            let studentId = uuid(
                d,
                "studentId"
            ),
            let driverId = uuid(
                d,
                "driverId"
            ),
            let statusString =
                string(
                    d,
                    "status"
                ),
            let status =
                RideStatus(
                    rawValue:
                        statusString
                )
        else {
            return nil
        }
        
        return Ride(
            id: id,
            studentId: studentId,
            driverId: driverId,
            parentId: uuid(
                d,
                "parentId"
            ),
            date: date(
                d,
                "date",
                fallback: Date()
            ),
            status: status,
            pickupTime: date(
                d,
                "pickupTime"
            ),
            dropoffTime: date(
                d,
                "dropoffTime"
            ),
            pickupLocation:
                string(
                    d,
                    "pickupLocation"
                ) ?? "",
            dropoffLocation:
                string(
                    d,
                    "dropoffLocation"
                ) ?? "",
            notes:
                string(
                    d,
                    "notes"
                ) ?? ""
        )
    }
    
    // MARK: - Payment Mapping
    
    private func paymentData(
        _ p: Payment
    ) -> [String: Any] {
        
        var data: [String: Any] = [
            "id":
                p.id.uuidString,
            "parentId":
                p.parentId.uuidString,
            "studentId":
                p.studentId.uuidString,
            "amount":
                p.amount,
            "date":
                Timestamp(date: p.date)
        ]
        
        if let driverId = p.driverId {
            data["driverId"] =
            driverId.uuidString
        }
        
        if let note = p.note,
           !note.trimmingCharacters(
            in: .whitespacesAndNewlines
           ).isEmpty
        {
            data["note"] =
            note
        }
        
        return data
    }
    
    private func payment(
        from d: [String: Any]
    ) -> Payment? {
        
        guard
            let id = uuid(
                d,
                "id"
            ),
            let parentId = uuid(
                d,
                "parentId"
            ),
            let studentId = uuid(
                d,
                "studentId"
            ),
            let amount =
                d["amount"] as? Double
        else {
            return nil
        }
        
        return Payment(
            id: id,
            parentId: parentId,
            studentId: studentId,
            driverId: uuid(
                d,
                "driverId"
            ),
            amount: amount,
            date: date(
                d,
                "date",
                fallback: Date()
            ),
            note: string(
                d,
                "note"
            )
        )
    }
    
    // MARK: - Expense Mapping
    
    private func expenseData(
        _ e: Expense
    ) -> [String: Any] {
        
        var data: [String: Any] = [
            "id":
                e.id.uuidString,
            "name":
                e.name,
            "amount":
                e.amount,
            "date":
                Timestamp(date: e.date)
        ]
        
        if let driverId = e.driverId {
            data["driverId"] =
            driverId.uuidString
            
            if let authUID =
                drivers.first(
                    where: {
                        $0.id == driverId
                    }
                )?.authUID
            {
                data["driverAuthUID"] =
                authUID
            }
        }
        
        return data
    }
    
    private func expense(
        from d: [String: Any]
    ) -> Expense? {
        
        guard
            let id = uuid(
                d,
                "id"
            ),
            let name = string(
                d,
                "name"
            ),
            let amount =
                d["amount"] as? Double
        else {
            return nil
        }
        
        return Expense(
            id: id,
            name: name,
            amount: amount,
            date: date(
                d,
                "date",
                fallback: Date()
            ),
            driverId: uuid(
                d,
                "driverId"
            )
        )
    }
    
    // MARK: - Log Mapping
    
    private func log(
        from d: [String: Any]
    ) -> Log? {
        
        guard
            let id = uuid(
                d,
                "id"
            ),
            let message =
                string(
                    d,
                    "message"
                )
        else {
            return nil
        }
        
        return Log(
            id: id,
            message: message,
            date: date(
                d,
                "date",
                fallback: Date()
            )
        )
    }
    
    // MARK: - Transportation Schedule Mapping
    
    private func transportationSchedule(
        from data: [String: Any]
    ) -> TransportationSchedule? {
        
        guard
            let id = uuid(
                data,
                "id"
            ),
            let parentId = uuid(
                data,
                "parentId"
            ),
            let studentId = uuid(
                data,
                "studentId"
            )
        else {
            return nil
        }
        
        return TransportationSchedule(
            id: id,
            parentId: parentId,
            studentId: studentId,
            driverId: uuid(
                data,
                "driverId"
            ) ?? <#default value#>,
            weekdays:
                data["weekdays"] as? [Int]
            ?? [2, 3, 4, 5, 6],
            morningPickupTime:
                date(
                    data,
                    "morningPickupTime"
                ),
            afternoonPickupTime:
                date(
                    data,
                    "afternoonPickupTime"
                ),
            pickupLocation:
                string(
                    data,
                    "pickupLocation"
                ) ?? "",
            schoolLocation:
                string(
                    data,
                    "schoolLocation"
                ) ?? "",
            homeLocation:
                string(
                    data,
                    "homeLocation"
                ) ?? "",
            isActive:
                data["isActive"] as? Bool
            ?? true,
            createdAt:
                date(
                    data,
                    "createdAt",
                    fallback: Date()
                ),
            updatedAt:
                date(
                    data,
                    "updatedAt",
                    fallback: Date()
                )
        )
    }
}
