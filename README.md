SafeRider

SafeRider is an iOS transportation management application designed to help parents, drivers, and administrators manage and monitor student transportation safely and efficiently.

🚗 Safe transportation. Connected families. Better visibility.

📱 Features

👨‍👩‍👧 Parents
Parent account registration and authentication 
Manage children/student profiles
View assigned drivers
Driver invitation and connection
Transportation schedules
Ride tracking
Payment information
Parent profile management
Notification preferences
Password management

🚐 Drivers
Driver authentication
Driver profile
Vehicle information
Parent/student connections
Driver invitations
Transportation tracking
Client/student management
Payment records
Expense management

👨‍💼 Administration
Administrative authentication
User management
Parent management
Driver management
Student management
Transportation management
Payment and expense monitoring


🏗️ Architecture

SafeRider uses a Firebase-backed architecture:

                    ┌──────────────────────┐
                    │      SafeRider       │
                    │      iOS App         │
                    │      SwiftUI         │
                    └──────────┬───────────┘
                               │
             ┌─────────────────┼─────────────────┐
             │                 │                 │
             ▼                 ▼                 ▼
      ┌────────────┐    ┌─────────────┐   ┌─────────────┐
      │ Firebase   │    │ Firestore   │   │   Storage   │
      │    Auth    │    │  Database   │   │    Files    │
      └────────────┘    └─────────────┘   └─────────────┘
             │                 │                 │
             ▼                 ▼                 ▼
          Identity         Application       Photos /
          & Login             Data           Documents

Technology Stack
Technology	                                Purpose
Swift	                                      Application language
SwiftUI	                                    User interface
Firebase Authentication	                    User identity
Cloud Firestore	                            Application database
Firebase Storage	                          Profile/banner images
Xcode	                                      Development environment
Git / GitHub	                              Source control

🗂️ Project Structure
SafeRiderApp/
│
├── SafeRider.xcodeproj
│
├── SafeRider/
│   │
│   ├── Models/
│   │
│   ├── AdminView/
│   │
│   ├── DriversView/
│   │
│   ├── ParentsView/
│   │
│   ├── StudentView/
│   │
│   └── ...
│
├── SafeRiderTests/
│
├── SafeRiderUITests/
│
├── firestore.rules
├── firebase.json
│
├── PHASE1_NOTES.md
└── PHASE2_FIREBASE.md
🔥 Firebase

SafeRider currently uses:

Firebase Authentication
Cloud Firestore
Firebase Storage

Core Firestore collections include:

users
parents
students
drivers
vehicles
rides
payments
expenses
notifications
systemLogs
transportationSchedules

The project also uses Firestore security rules to control access to application data.

🔐 Authentication

SafeRider uses Firebase Authentication for account identity.

Supported application roles:

Parent
Driver
Admin

The user's role is stored in the application's users collection and determines the appropriate application experience.

🚗 Transportation Flow

A typical SafeRider transportation workflow is:

Parent
   │
   │ invites driver
   ▼
Driver
   │
   │ accepts invitation
   ▼
Parent ↔ Driver
   │
   │ student assignment
   ▼
Transportation Schedule
   │
   ▼
Ride
   │
   ├── Scheduled
   ├── Driver En Route
   ├── Picked Up
   ├── Dropped at School
   ├── Returning
   └── Arrived Home
   
🧪 Development
Requirements
macOS
Xcode
Swift
Firebase account
Git
GitHub account

Clone the repository:

git clone git@github.com:ritzardB/SafeRiderApp.git
cd SafeRiderApp

Open:

open SafeRider.xcodeproj

Configure the Firebase project and build the application using Xcode.

📊 Development Roadmap

Phase 1 — Foundation
 SwiftUI application
 Project architecture
 Authentication
 Parent interface
 Driver interface
 Admin interface
 Student management
 
Phase 2 — Firebase
 Firebase Authentication
 Firestore integration
 Firebase Storage
 Firestore security rules
 User roles
 Transportation data model
 
Phase 3 — Transportation
 Driver invitations
 Student assignments
 Transportation schedules
 Real-time ride tracking
 Driver location updates
 Parent live tracking
 
Phase 4 — Operations
 Payment workflow
 Expense reporting
 Notifications
 Administrative dashboard
 Reporting and analytics
 
Phase 5 — Production
 Comprehensive testing
 Security review
 Performance optimization
 App Store configuration
 Production deployment
 
🧭 Project Status

Current status: 🚧 Active Development

SafeRider is currently being developed as a native iOS application using SwiftUI and Firebase.

The project is being developed incrementally, with each phase documented in the repository.

📄 Documentation

Development documentation:

PHASE1_NOTES.md — Initial application architecture and development notes

PHASE2_FIREBASE.md — Firebase integration and backend configuration
⚠️ Important

SafeRider is currently a development project and should not yet be considered production-ready transportation software.

Before production deployment, additional work is required around security, privacy, real-time location handling, notifications, testing, operational policies, and App Store compliance.

License

License information will be added as the project approaches public release.
