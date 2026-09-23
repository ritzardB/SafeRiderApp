import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import FirebaseAuth

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
    
    // MARK: - Identity Document Upload

    @State private var selectedDocumentType: IdentityDocumentType = .driverLicense
    @State private var selectedDocument: URL?
    @State private var isUploadingIdentity = false
    @State private var identityError: String?
    @State private var identitySuccess: String?
    @State private var showingDocumentPicker = false
    @State private var countryOfIssue = "United Arab Emirates"
    @State private var expiresAt: Date?

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
                
                // MARK: - Identity Verification

                Section("Identity Verification") {

                    Picker("Document Type", selection: $selectedDocumentType) {
                        ForEach(IdentityDocumentType.allCases) { type in
                            Text(type.title)
                                .tag(type)
                        }
                    }

                    TextField("Country of Issue", text: $countryOfIssue)

                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Label(
                            "Select Identity Document",
                            systemImage: "doc.badge.plus"
                        )
                    }

                    if let selectedDocument {
                        Label(
                            selectedDocument.lastPathComponent,
                            systemImage: "doc.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(SafeRiderTheme.secondaryText)
                    }

                    Button {
                        Task {
                            await uploadIdentityDocument()
                        }
                    } label: {
                        if isUploadingIdentity {
                            ProgressView("Uploading Document...")
                        } else {
                            Label("Upload Document", systemImage: "icloud.and.arrow.up")
                        }
                    }
                    .disabled(selectedDocument == nil || isUploadingIdentity)

                    if let identitySuccess {
                        Text(identitySuccess)
                            .font(.caption)
                            .foregroundStyle(SafeRiderTheme.success)
                    }

                    Text(
                        "Your identity document will be securely submitted for review."
                    )
                    .font(.caption)
                    .foregroundStyle(SafeRiderTheme.secondaryText)
                }
                
                .fileImporter(
                    isPresented: $showingDocumentPicker,
                    allowedContentTypes: [.pdf, .jpeg, .png],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        selectedDocument = urls.first

                    case .failure(let error):
                        identityError = error.localizedDescription
                    }
                }
                
                // MARK: - Settings

                Section("Settings") {
                    NavigationLink {
                        DriverSettingsView()
                    } label: {
                        Label(
                            "Settings & Account",
                            systemImage: "gearshape"
                        )
                    }
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
        
        .alert(
            "Identity Upload Error",
            isPresented: Binding(
                get: { identityError != nil },
                set: { if !$0 { identityError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(identityError ?? "")
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
    
    // MARK: - Upload Identity Document

    private func uploadIdentityDocument() async {
        guard let selectedDocument,
              let uid = Auth.auth().currentUser?.uid else {
            identityError = "Unable to identify the authenticated driver."
            return
        }

        isUploadingIdentity = true
        defer {
            isUploadingIdentity = false
        }

        do {
            let didAccess = selectedDocument.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    selectedDocument.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: selectedDocument)

            let fileExtension = selectedDocument.pathExtension.lowercased()

            let contentType: String
            switch fileExtension {
            case "pdf":
                contentType = "application/pdf"
            case "jpg", "jpeg":
                contentType = "image/jpeg"
            case "png":
                contentType = "image/png"
            default:
                throw NSError(
                    domain: "SafeRider.Identity",
                    code: 400,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "Unsupported document format."
                    ]
                )
            }

            let storagePath = try await StorageManager.shared
                .uploadDriverIdentityDocument(
                    data: data,
                    identifier: uid,
                    fileExtension: fileExtension,
                    contentType: contentType
                )

            let document = DriverIdentityDocument(
                driverAuthUID: uid,
                documentType: selectedDocumentType,
                countryOfIssue: countryOfIssue,
                storagePath: storagePath,
                expiresAt: expiresAt,
                status: .pending
            )

            try await dataManager.submitDriverIdentityDocument(document)

            identitySuccess = "Document submitted for review."
            identityError = nil
            self.selectedDocument = nil

        } catch {
            identityError = error.localizedDescription
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
