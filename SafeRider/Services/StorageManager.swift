//
//  StorageManager.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 07/09/2026.
//

import Foundation
import UIKit
import FirebaseStorage
import UniformTypeIdentifiers

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
    
    // MARK: - Driver Identity Document

    func uploadDriverIdentityDocument(
        data: Data,
        identifier: String,
        fileExtension: String,
        contentType: String
    ) async throws -> String {

        // Validate file size (maximum 10 MB)
        let maxFileSize = 10 * 1024 * 1024

        guard !data.isEmpty, data.count <= maxFileSize else {
            throw StorageError.invalidFileSize
        }

        // Validate allowed file types
        let allowedTypes: [String: String] = [
            "pdf": "application/pdf",
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png"
        ]

        let normalizedExtension = fileExtension.lowercased()

        guard let expectedContentType = allowedTypes[normalizedExtension],
              expectedContentType == contentType else {
            throw StorageError.invalidFileType
        }
        
        // MARK: - Storage Errors

        enum StorageError: LocalizedError {
            case imageConversionFailed
            case uploadFailed
            case invalidFileSize
            case invalidFileType

            var errorDescription: String? {
                switch self {
                case .imageConversionFailed:
                    return "Unable to convert the selected image to JPEG."

                case .uploadFailed:
                    return "The image upload failed."

                case .invalidFileSize:
                    return "The document must be greater than 0 bytes and no larger than 10 MB."

                case .invalidFileType:
                    return "Only PDF, JPEG, and PNG documents are supported."
                }
            }
        }

        // Generate a unique document identifier
        let documentID = UUID().uuidString

        // Store document in a dedicated private directory
        let reference = storage
            .reference()
            .child("driverIdentityDocuments")
            .child(identifier)
            .child("\(documentID).\(normalizedExtension)")

        let metadata = StorageMetadata()
        metadata.contentType = contentType

        // Upload document
        _ = try await reference.putDataAsync(
            data,
            metadata: metadata
        )

        // Return Storage path only — never a public download URL
        return reference.fullPath
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
