//
//  DriverInvitationManager.swift
//  SafeRider
//
//  Creates secure driver invitations for parents.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import Security

@MainActor
final class DriverInvitationManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isCreatingInvitation = false
    @Published var errorMessage: String?

    // MARK: - Firebase

    private let db = Firestore.firestore()

    // MARK: - Create Invitation

    func createInvitation(
        parent: Parent,
        studentId: UUID? = nil
    ) async -> Result<InvitationResult, Error> {

        // ---------------------------------------------------------
        // Verify authentication
        // ---------------------------------------------------------

        guard let currentUser = Auth.auth().currentUser else {
            let error = InvitationError.notAuthenticated
            errorMessage = error.localizedDescription
            return .failure(error)
        }

        isCreatingInvitation = true
        errorMessage = nil

        defer {
            isCreatingInvitation = false
        }

        do {

            // -----------------------------------------------------
            // Generate secure token
            // -----------------------------------------------------

            let token = try generateSecureToken()

            let invitationId = UUID()
            let createdAt = Date()

            // -----------------------------------------------------
            // Invitation validity
            //
            // 24 hours from creation.
            // -----------------------------------------------------

            let expiresAt =
                createdAt.addingTimeInterval(
                    24 * 60 * 60
                )

            // -----------------------------------------------------
            // Firestore invitation data
            // -----------------------------------------------------

            var data: [String: Any] = [

                "id":
                    invitationId.uuidString,

                // SafeRider Parent UUID
                "parentId":
                    parent.id.uuidString,

                // Firebase Authentication UID
                "parentAuthUID":
                    currentUser.uid,

                // SHA-256 hash of invitation token
                "tokenHash":
                    token.hash,

                "status":
                    DriverConnectionStatus
                        .pending
                        .rawValue,

                "createdAt":
                    Timestamp(date: createdAt),

                "expiresAt":
                    Timestamp(date: expiresAt)
            ]

            // Only store studentId if a specific
            // student was selected.

            if let studentId {
                data["studentId"] =
                    studentId.uuidString
            }

            // -----------------------------------------------------
            // Save invitation
            // -----------------------------------------------------

            try await db
                .collection("driverInvitations")
                .document(invitationId.uuidString)
                .setData(data)

            // -----------------------------------------------------
            // Return local connection representation
            // -----------------------------------------------------

            let connection = DriverConnection(
                id: invitationId,
                parentId: parent.id,
                driverId: nil,
                driverAuthUID: nil,
                studentId: studentId,
                source: .invitation,
                status: .pending,
                createdAt: createdAt,
                acceptedAt: nil,
                expiresAt: expiresAt
            )

            return .success(
                InvitationResult(
                    connection: connection,
                    token: token.value
                )
            )

        } catch {

            errorMessage =
                error.localizedDescription

            return .failure(error)
        }
    }

    // MARK: - Secure Token

    private func generateSecureToken()
        throws -> SecureInvitationToken {

        let characters =
            Array(
                "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
            )

        var bytes = [UInt8](
            repeating: 0,
            count: 12
        )

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            throw InvitationError
                .tokenGenerationFailed
        }

        let value = bytes.map { byte in
            characters[
                Int(byte) % characters.count
            ]
        }

        let token = String(value)

        let hash =
            InvitationTokenHasher.hash(token)

        return SecureInvitationToken(
            value: token,
            hash: hash
        )
    }
}

// MARK: - Invitation Result

struct InvitationResult {

    let connection: DriverConnection

    let token: String
}

// MARK: - Secure Token

private struct SecureInvitationToken {

    let value: String

    let hash: String
}

// MARK: - Token Hasher

enum InvitationTokenHasher {

    static func normalize(
        _ token: String
    ) -> String {

        token
            .trimmingCharacters(
                in: .whitespacesAndNewlines)
                    .uppercased()
    }

    static func hash(
        _ token: String
    ) -> String {

        let normalized =
            normalize(token)

        let data =
            Data(normalized.utf8)

        let digest =
            SHA256.hash(data: data)

        return digest
            .map {
                String(format: "%02x", $0)
            }
            .joined()
    }
}

// MARK: - Invitation Errors

enum InvitationError: LocalizedError {

    case notAuthenticated

    case tokenGenerationFailed

    var errorDescription: String? {

        switch self {

        case .notAuthenticated:
            return """
            You must be signed in to create an invitation.
            """

        case .tokenGenerationFailed:
            return """
            Unable to generate a secure invitation token.
            """
        }
    }
}
