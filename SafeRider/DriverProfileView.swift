import SwiftUI
import PhotosUI

struct DriverProfileView: View {

    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    let driver: Driver

    @State private var name: String
    @State private var licenseNumber: String
    @State private var vehicleNumber: String
    @State private var vehicleType: String
    @State private var email: String
    @State private var phoneNumber: String

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploadingPhoto = false
    @State private var photoError: String?

    init(driver: Driver) {
        self.driver = driver

        _name = State(initialValue: driver.name)
        _licenseNumber = State(initialValue: driver.licenseNumber)
        _vehicleNumber = State(initialValue: driver.vehicleNumber)
        _vehicleType = State(initialValue: driver.vehicleType)
        _email = State(initialValue: driver.email)
        _phoneNumber = State(initialValue: driver.phoneNumber)
    }

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {

                // MARK: - Profile Photo

                Section {
                    VStack(spacing: 8) {

                        ZStack(alignment: .bottom) {

                            // Avatar
                            Group {
                                if let selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ProfileAvatarView(
                                        name: name.isEmpty
                                            ? "Driver"
                                            : name,
                                        photoURL: driver.photoURL,
                                        size: 120
                                    )
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        .white,
                                        lineWidth: 4
                                    )
                            }
                            .shadow(
                                color: .black.opacity(0.15),
                                radius: 6,
                                y: 3
                            )

                            // Camera button
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            .black.opacity(0.75)
                                        )
                                        .frame(
                                            width: 42,
                                            height: 42
                                        )

                                    Image(
                                        systemName: "camera.fill"
                                    )
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(.white)
                                }
                                .overlay {
                                    Circle()
                                        .stroke(
                                            .white,
                                            lineWidth: 2
                                        )
                                }
                            }
                            .offset(y: 6)
                            .disabled(isUploadingPhoto)
                        }

                        if isUploadingPhoto {
                            ProgressView(
                                "Uploading photo..."
                            )
                            .font(.caption)
                            .padding(.top, 8)
                        } else {
                            Text(
                                "Tap the camera icon to change your photo"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                            .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                // MARK: - Driver Information

                Section("Driver Information") {
                    TextField(
                        "Full Name",
                        text: $name
                    )

                    TextField(
                        "License Number",
                        text: $licenseNumber
                    )

                    TextField(
                        "Phone Number",
                        text: $phoneNumber
                    )
                    .keyboardType(.phonePad)

                    TextField(
                        "Email",
                        text: $email
                    )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                }

                // MARK: - Vehicle

                Section("Vehicle") {
                    TextField(
                        "Vehicle Number",
                        text: $vehicleNumber
                    )

                    TextField(
                        "Vehicle Type",
                        text: $vehicleType
                    )
                }

                // MARK: - Account

                Section("Account") {
                    if let authUID = driver.authUID,
                       !authUID.isEmpty {

                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text("Current Account")
                                .font(.caption)
                                .foregroundStyle(
                                    SafeRiderTheme.secondaryText
                                )

                            Text("Active")
                                .foregroundStyle(
                                    SafeRiderTheme.success
                                )
                        }

                    } else {

                        Text(
                            "Firebase account is not linked."
                        )
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }
                }
                Section {
                    Button(role: .destructive) {
                        logout()
                    } label: {
                        HStack {
                            Spacer()

                            Label(
                                "Log Out",
                                systemImage: "rectangle.portrait.and.arrow.right"
                            )
                            .fontWeight(.semibold)

                            Spacer()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Driver Profile")
        .toolbar {
            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("Save") {
                    saveProfile()
                }
                .foregroundStyle(SafeRiderTheme.orange)
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .alert(
            "Photo Upload Error",
            isPresented: Binding(
                get: {
                    photoError != nil
                },
                set: { newValue in
                    if !newValue {
                        photoError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoError ?? "")
        }
    }

    // MARK: - Load Selected Photo

    private func loadSelectedPhoto() async {

        guard let selectedPhoto else {
            return
        }

        do {

            guard let data = try await selectedPhoto
                .loadTransferable(type: Data.self)
            else {
                return
            }

            guard let image = UIImage(data: data) else {
                return
            }

            // Show the selected image immediately
            selectedImage = image

            // Upload to Firebase Storage
            await uploadProfilePhoto(image)

        } catch {

            photoError = error.localizedDescription
        }
    }

    // MARK: - Upload Profile Photo

    private func uploadProfilePhoto(
        _ image: UIImage
    ) async {

        isUploadingPhoto = true

        defer {
            isUploadingPhoto = false
        }

        do {

            let photoURL = try await StorageManager.shared
                .uploadProfilePhoto(
                    image: image,
                    type: .driver,
                    identifier: driver.id.uuidString
                )

            var updatedDriver = driver

            updatedDriver.photoURL = photoURL

            dataManager.updateDriver(updatedDriver)

        } catch {

            photoError = error.localizedDescription
        }
    }

    // MARK: - Save Profile

    private func saveProfile() {

        var updatedDriver = driver

        updatedDriver.name = name
        updatedDriver.licenseNumber = licenseNumber
        updatedDriver.vehicleNumber = vehicleNumber
        updatedDriver.email = email
        updatedDriver.phoneNumber = phoneNumber

        // Preserve the newly uploaded photo URL
        if let selectedImage,
           driver.photoURL == nil {

            _ = selectedImage
        }

        dataManager.updateDriver(updatedDriver)

        dismiss()
    }
    
    private func logout() {
        authManager.logout()
    }
}
