import SwiftUI
import PhotosUI

struct StudentProfileView: View {
    @EnvironmentObject private var dataManager: DataManager

    let student: Student

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var notificationMessage: NotificationMessage?
 

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            List {

                // MARK: - Student Profile

                Section {
                    ZStack(alignment: .bottomLeading) {

                        // MARK: Background Photo

                        ZStack {
                            SafeRiderTheme.orange

                            if let previewImage {
                                Image(uiImage: previewImage)
                                    .resizable()
                                    .scaledToFill()

                            } else if let photoURL = student.photoURL,
                                      let url = URL(string: photoURL) {

                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        SafeRiderTheme.orange
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        
                        // MARK: Gradient Overlay

                        LinearGradient(
                            colors: [
                                .black.opacity(0.05),
                                .black.opacity(0.25),
                                .black.opacity(0.75)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // MARK: Student Details

                        HStack(alignment: .bottom, spacing: 16) {

                            // Student Avatar

                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Group {
                                    if let previewImage {
                                        Image(uiImage: previewImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        ProfileAvatarView(
                                            name: student.name,
                                            photoURL: student.photoURL,
                                            size: 82
                                        )
                                    }
                                }
                                .frame(width: 82, height: 82)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(7)
                                        .background(SafeRiderTheme.orange)
                                        .clipShape(Circle())
                                        .overlay {
                                            Circle()
                                                .stroke(.white, lineWidth: 1.5)
                                        }
                                }
                            }
                            .disabled(isUploadingPhoto)

                            // Name and Grade

                            VStack(alignment: .leading, spacing: 5) {
                                Text(student.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)

                                Text("\(student.grade) • \(student.section)")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.9))
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(20)

                        // MARK: Upload Indicator

                        if isUploadingPhoto {
                            ProgressView("Uploading photo...")
                                .tint(.white)
                                .padding(8)
                                .background(.black.opacity(0.5))
                                .clipShape(Capsule())
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .topTrailing
                                )
                                .padding(12)
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .listRowInsets(
                        EdgeInsets(
                            top: 0,
                            leading: 16,
                            bottom: 8,
                            trailing: 16
                        )
                    )
                    .listRowBackground(Color.clear)
                }

                // MARK: - Student Information

                Section("Child Information") {
                    LabeledContent("Name") {
                        Text(student.name)
                    }

                    LabeledContent("Grade") {
                        Text(student.grade)
                    }

                    LabeledContent("Section") {
                        Text(student.section)
                    }
                    
                    addressRow(
                                title: "Home Address",
                                icon: "house.fill",
                                address: student.homeAddress
                            )
                }
                

                // MARK: - School Information

                Section("School Information") {
                    LabeledContent("School") {
                        Text(
                            student.school.isEmpty
                                ? "Not provided"
                                : student.school
                        )
                    }
                    addressRow(
                                title: "School Address",
                                icon: "building.2.fill",
                                address: student.schoolAddress
                            )

                    LabeledContent("Teacher") {
                        Text(
                            student.teacherName.isEmpty
                                ? "Not provided"
                                : student.teacherName
                        )
                    }

                    if !student.teacherPhone.isEmpty {
                        LabeledContent("Teacher Phone") {
                            Text(student.teacherPhone)
                        }
                    }
                }
                
                // MARK: - Payment Arrangement

                Section("Payment Arrangement") {
                    if let arrangement = dataManager.paymentArrangements.first(
                        where: { $0.studentId == student.id }
                    ) {
                        LabeledContent("Frequency") {
                            Text(arrangement.paymentFrequency.rawValue)
                        }

                        LabeledContent("Amount") {
                            Text(
                                arrangement.amount,
                                format: .currency(code: "AED")
                            )
                        }

                        if let dueDay = arrangement.dueDay {
                            LabeledContent("Payment Day") {
                                Text("Day \(dueDay) of the month")
                            }
                        }

                        if let dueWeekday = arrangement.dueWeekday {
                            LabeledContent("Payment Day") {
                                Text(weekdayName(dueWeekday))
                            }
                        }

                        LabeledContent("Next Due Date") {
                            Text(arrangement.nextDueDate, style: .date)
                        }

                        LabeledContent("Status") {
                            Text(arrangement.isActive ? "Active" : "Inactive")
                                .foregroundStyle(
                                    arrangement.isActive
                                        ? .green
                                        : SafeRiderTheme.secondaryText
                                )
                        }
                    } else {
                        Text("No payment arrangement configured.")
                            .font(.subheadline)
                            .foregroundStyle(SafeRiderTheme.secondaryText)
                    }
                }
                

                // MARK: - Transportation

                Section("Transportation") {
                    if let driverId = student.driverId,
                       let driver = dataManager.drivers.first(
                           where: { $0.id == driverId }
                       ) {

                        LabeledContent("Driver") {
                            Text(
                                driver.name.isEmpty
                                    ? driver.email
                                    : driver.name
                            )
                        }

                        if !driver.vehicleNumber.isEmpty {
                            LabeledContent("Vehicle") {
                                Text(driver.vehicleNumber)
                            }
                        }

                        if !driver.phoneNumber.isEmpty {
                            LabeledContent("Driver Phone") {
                                Text(driver.phoneNumber)
                            }
                        }

                    } else {
                        Text("No driver assigned")
                            .foregroundStyle(SafeRiderTheme.secondaryText)
                    }
                }

                // MARK: - Ride Operations

                Section("Ride Operations") {
                    Button {
                        updateRide(.pickedUp)
                    } label: {
                        Label(
                            "Picked Up",
                            systemImage: "person.fill.checkmark"
                        )
                    }

                    Button {
                        updateRide(.droppedAtSchool)
                    } label: {
                        Label(
                            "Arrived at School",
                            systemImage: "building.2.fill"
                        )
                    }

                    Button {
                        updateRide(.arrivedHome)
                    } label: {
                        Label(
                            "Arrived Home Safely",
                            systemImage: "house.fill"
                        )
                    }
                }

                // MARK: - Ride History

                Section("Ride History") {
                    NavigationLink {
                        RideHistoryView(student: student)
                    } label: {
                        Label(
                            "View Ride History",
                            systemImage: "clock.arrow.circlepath"
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(.insetGrouped)
        }
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    EditStudentView(student: student)
                        .environmentObject(dataManager)
                } label: {
                    Label(
                        "Edit",
                        systemImage: "pencil"
                    )
                }
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
            }
        }
        .task(id: selectedPhoto) {
            await handleSelectedPhoto()
        }
        .alert(item: $notificationMessage) { message in
            Alert(
                title: Text("Ride Updated"),
                message: Text(message.text),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Payment Arrangement Helpers

    private func weekdayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        guard let weekdays = formatter.weekdaySymbols,
              (1...7).contains(weekday) else {
            return "Not specified"
        }

        return weekdays[weekday - 1]
    }
    
    private func addressRow(
        title: String,
        icon: String,
        address: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Image(systemName: icon)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                if address.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty {
                    Text("Not configured")
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                } else {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                }
            }

            Spacer()
        }
    }

    // MARK: - Photo Upload

    private func handleSelectedPhoto() async {
        guard let selectedPhoto else {
            return
        }

        do {
            guard let data = try await selectedPhoto.loadTransferable(
                type: Data.self
            ),
            let image = UIImage(data: data) else {
                return
            }

            previewImage = image
            isUploadingPhoto = true

            let url = try await StorageManager.shared.uploadStudentProfilePhoto(
                image: image,
                identifier: student.id.uuidString
            )

            dataManager.updateStudentPhotoURL(
                studentId: student.id,
                photoURL: url
            )

            isUploadingPhoto = false
            self.selectedPhoto = nil

        } catch {
            isUploadingPhoto = false
            self.selectedPhoto = nil

            notificationMessage = NotificationMessage(
                text: "Unable to upload the child photo: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Ride Update

    private func updateRide(_ status: RideStatus) {
        guard let driver = dataManager.currentDriver else {
            notificationMessage = NotificationMessage(
                text: "No current driver is available."
            )
            return
        }

        _ = dataManager.updateTodayRide(
            studentId: student.id,
            driverId: driver.id,
            status: status
        )

        notificationMessage = NotificationMessage(
            text: "\(student.name) is now marked as \(status.displayName)."
        )
    }
}
