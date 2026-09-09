//
//  StorageManager.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 07/09/2026.
//

import Foundation
import UIKit
import FirebaseStorage

final class StorageManager {

    static let shared = StorageManager()

    private let storage = Storage.storage()

    private init() {}

    // MARK: - Profile Types

    enum ProfileType {
        case driver
        case parent
        case school
        case student

        var folderName: String {
            switch self {
            case .driver:
                return "drivers"
            case .parent:
                return "parents"
            case .school:
                return "schools"
            case .student:
                return "students"
            }
        }
    }

    // MARK: - Upload Profile Photo

    func uploadProfilePhoto(
        image: UIImage,
        type: ProfileType,
        identifier: String
    ) async throws -> String {

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw StorageError.imageConversionFailed
        }

        let reference = storage
            .reference()
            .child("profilePhotos")
            .child(type.folderName)
            .child("\(identifier).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await reference.putDataAsync(
            imageData,
            metadata: metadata
        )

        return try await reference.downloadURL().absoluteString
    }

    // MARK: - Driver Photo

    func uploadDriverProfilePhoto(
        image: UIImage,
        identifier: String
    ) async throws -> String {

        try await uploadProfilePhoto(
            image: image,
            type: .driver,
            identifier: identifier
        )
    }

    // MARK: - Parent Photo

    func uploadParentProfilePhoto(
        image: UIImage,
        identifier: String
    ) async throws -> String {

        try await uploadProfilePhoto(
            image: image,
            type: .parent,
            identifier: identifier
        )
    }

    // MARK: - Student Photo

    func uploadStudentProfilePhoto(
        image: UIImage,
        identifier: String
    ) async throws -> String {

        try await uploadProfilePhoto(
            image: image,
            type: .student,
            identifier: identifier
        )
    }

    // MARK: - Parent Banner

    func uploadParentBanner(
        image: UIImage,
        identifier: String
    ) async throws -> String {

        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw StorageError.imageConversionFailed
        }

        let reference = storage
            .reference()
            .child("profileBanners")
            .child("parents")
            .child("\(identifier).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await reference.putDataAsync(
            imageData,
            metadata: metadata
        )

        return try await reference.downloadURL().absoluteString
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case imageConversionFailed
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Unable to convert the selected image to JPEG."

        case .uploadFailed:
            return "The image upload failed."
        }
    }
}
