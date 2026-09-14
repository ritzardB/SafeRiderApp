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
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Group {
                                if let previewImage {
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ProfileAvatarView(
                                        name: student.name,
                                        photoURL: student.photoURL,
                                        size: 120
                                    )
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())

                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ZStack {
                                    Circle()
                                        .fill(SafeRiderTheme.orange)
                                        .frame(width: 38, height: 38)

                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                )
                            }
                            .disabled(isUploadingPhoto)
                        }

                        Text(student.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(SafeRiderTheme.primaryText)

                        Text("\(student.grade) • \(student.section)")
                            .font(.subheadline)
                            .foregroundStyle(SafeRiderTheme.secondaryText)

                        if isUploadingPhoto {
                            ProgressView("Uploading photo...")
                                .tint(SafeRiderTheme.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.white)
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

        dataManager.updateTodayRide(
            studentId: student.id,
            driverId: driver.id,
            status: status
        )

        notificationMessage = NotificationMessage(
            text: "\(student.name) is now marked as \(status.displayName)."
        )
    }
}
