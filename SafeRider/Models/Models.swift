import Foundation

enum UserRole: String, Codable, CaseIterable {
    case parent
    case driver
    case admin
}

enum RideStatus: String, Codable, CaseIterable {
    case scheduled
    case driverEnRoute
    case pickedUp
    case droppedAtSchool
    case returning
    case arrivedHome
    case cancelled

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .driverEnRoute: return "Driver En Route"
        case .pickedUp: return "Picked Up"
        case .droppedAtSchool: return "Dropped at School"
        case .returning: return "Returning"
        case .arrivedHome: return "Arrived Home"
        case .cancelled: return "Cancelled"
        }
    }
}

struct Parent: Identifiable, Codable {
    var id: UUID = UUID()
    var authUID: String? = nil
    var motherName: String = ""
    var fatherName: String = ""
    var email: String = ""
    var contactNumber: String = ""
    var photoURL: String? = nil
    var bannerURL: String? = nil
}

struct Student: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var grade: String
    var section: String
    var teacherName: String
    var teacherPhone: String
    var parentId: UUID?
    var driverId: UUID?
    var school: String
    
    var photoURL: String? = nil
    
    // MARK: - Student Locations

    var homeAddress: String = ""
    var homeLatitude: Double?
    var homeLongitude: Double?

    var schoolAddress: String = ""
    var schoolLatitude: Double?
    var schoolLongitude: Double?
}

struct School: Identifiable, Codable {
    var id: UUID = UUID()
    var schoolName: String
    var address: String
    var contactNumber: String
    var principalName: String
    var administratorName: String
    var photoURL: String? = nil
}

struct Driver: Identifiable, Codable {
    var id: UUID = UUID()
    var authUID: String? = nil
    var name: String
    var licenseNumber: String
    var vehicleNumber: String
    var vehicleType: String
    var email: String
    var phoneNumber: String
    var photoURL: String? = nil
}

enum DriverConnectionSource: String, Codable, CaseIterable {
    case directory
    case invitation
}

enum DriverConnectionStatus: String, Codable, CaseIterable {
    case pending
    case active
    case declined
    case expired
    case revoked
}

struct DriverConnection: Identifiable, Codable {
    var id: UUID = UUID()

    var parentId: UUID
    var driverId: UUID?
    var driverAuthUID: String?

    var studentId: UUID?

    var source: DriverConnectionSource = .directory
    var status: DriverConnectionStatus = .pending

    var createdAt: Date = Date()
    var acceptedAt: Date?
    var expiresAt: Date?
}
struct TransportationSchedule: Identifiable, Codable {
    var id: UUID = UUID()
    var parentId: UUID
    var studentId: UUID
    var driverId: UUID

    /// Days on which the schedule is active.
    /// 1 = Sunday, 2 = Monday ... 7 = Saturday.
    var weekdays: [Int] = [2, 3, 4, 5, 6]

    /// Regular morning pickup time.
    var morningPickupTime: Date?

    /// Regular afternoon pickup from school.
    var afternoonPickupTime: Date?

    var pickupLocation: String = ""
    var schoolLocation: String = ""
    var homeLocation: String = ""
    
    // Location customization
    var isCustomPickupLocation: Bool = false
    var isCustomSchoolLocation: Bool = false
    var isCustomDropoffLocation: Bool = false

    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

struct Ride: Identifiable, Codable {
    var id: UUID = UUID()
    var studentId: UUID
    var driverId: UUID
    var parentId: UUID? = nil
    var date: Date = Date()
    var status: RideStatus = .scheduled
    var pickupTime: Date?
    var dropoffTime: Date?
    var pickupLocation: String = ""
    var dropoffLocation: String = ""
    var notes: String = ""
}

struct Payment: Identifiable, Codable {
    var id: UUID = UUID()

    var parentId: UUID
    var studentId: UUID
    var driverId: UUID?

    var amount: Double
    var date: Date
    var note: String?

    init(
        id: UUID = UUID(),
        parentId: UUID,
        studentId: UUID,
        driverId: UUID? = nil,
        amount: Double,
        date: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.studentId = studentId
        self.driverId = driverId
        self.amount = amount
        self.date = date
        self.note = note
    }
}

struct Expense: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var date: Date
    var driverId: UUID? = nil
}

struct Log: Identifiable, Codable {
    var id: UUID = UUID()
    var message: String
    var date: Date
}

