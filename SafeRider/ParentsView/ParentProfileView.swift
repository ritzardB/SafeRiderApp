import SwiftUI
import PhotosUI

struct ParentProfileView: View {
    @EnvironmentObject private var dataManager: DataManager

    @Environment(\.dismiss) private var dismiss

    @State private var parent: Parent

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    @State private var isUploadingPhoto = false
    @State private var photoError: String?

    @State private var saveTask: Task<Void, Never>?

    init(parent: Parent) {
        _parent = State(initialValue: parent)
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

                            Group {
                                if let selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ProfileAvatarView(
                                        name: parentDisplayName,
                                        photoURL: parent.photoURL,
                                        size: 120
                                    )
                                }
                            }
                            .frame(
                                width: 120,
                                height: 120
                            )
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

                // MARK: - Profile Information

                Section("Profile Information") {

                    TextField(
                        "Mother Name",
                        text: $parent.motherName
                    )
                    .onChange(of: parent.motherName) {
                        scheduleAutosave()
                    }

                    TextField(
                        "Father Name",
                        text: $parent.fatherName
                    )
                    .onChange(of: parent.fatherName) {
                        scheduleAutosave()
                    }

                    TextField(
                        "Contact Number",
                        text: $parent.contactNumber
                    )
                    .keyboardType(.phonePad)
                    .onChange(of: parent.contactNumber) {
                        scheduleAutosave()
                    }
                }

                // MARK: - Account

                Section("Account") {

                    HStack {
                        Text("Email")

                        Spacer()

                        Text(
                            parent.email.isEmpty
                                ? "Not available"
                                : parent.email
                        )
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                        .multilineTextAlignment(
                            .trailing
                        )
                    }

                    HStack {
                        Text("Status")

                        Spacer()

                        Label(
                            "Active",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                    }
                }

                // MARK: - Settings

                Section {
                    NavigationLink {
                        ParentSettingsView()
                    } label: {
                        Label(
                            "Settings",
                            systemImage: "gearshape.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("My Profile")
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

    // MARK: - Parent Name

    private var parentDisplayName: String {
        if !parent.motherName.isEmpty {
            return parent.motherName
        }

        if !parent.fatherName.isEmpty {
            return parent.fatherName
        }

        if !parent.email.isEmpty {
            return parent.email
        }

        return "Parent"
    }

    // MARK: - Autosave

    private func scheduleAutosave() {
        saveTask?.cancel()

        saveTask = Task {
            try? await Task.sleep(
                for: .milliseconds(600)
            )

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                dataManager.updateParent(parent)
            }
        }
    }

    // MARK: - Photo

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

            selectedImage = image

            await uploadProfilePhoto(image)

        } catch {
            photoError = error.localizedDescription
        }
    }

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
                    type: .parent,
                    identifier: parent.id.uuidString
                )

            parent.photoURL = photoURL

            dataManager.updateParent(parent)

        } catch {
            photoError = error.localizedDescription
        }
    }
}
