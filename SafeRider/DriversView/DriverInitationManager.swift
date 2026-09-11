import Foundation
import FirebaseAuth
import FirebaseFirestore
import CryptoKit
import Security

@MainActor
final class DriverInvitationManager: ObservableObject {

    @Published private(set) var isCreatingInvitation = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func createInvitation(
        parent: Parent,
        studentId: UUID? = nil
    ) async -> Result<InvitationResult, Error> {

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
            let token = try generateSecureToken()

            let invitationId = UUID()
            let createdAt = Date()
            let expiresAt = createdAt.addingTimeInterval(10 * 60)

            let data: [String: Any] = [
                "id": invitationId.uuidString,
                "parentId": parent.id.uuidString,
                "parentAuthUID": currentUser.uid,
                "tokenHash": token.hash,
                "status": DriverConnectionStatus.pending.rawValue,
                "studentId": studentId?.uuidString as Any,
                "createdAt": Timestamp(date: createdAt),
                "expiresAt": Timestamp(date: expiresAt)
            ]

            try await db
                .collection("driverInvitations")
                .document(invitationId.uuidString)
                .setData(data)

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
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    // MARK: - Secure Token

    private func generateSecureToken() throws -> SecureInvitationToken {
        let characters = Array(
            "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        )

        var bytes = [UInt8](repeating: 0, count: 12)

        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            bytes.count,
            &bytes
        )

        guard status == errSecSuccess else {
            throw InvitationError.tokenGenerationFailed
        }

        let value = bytes.map {
            characters[Int($0) % characters.count]
        }

        let token = String(value)

        return SecureInvitationToken(
            value: token,
            hash: token.sha256
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

// MARK: - Errors

enum InvitationError: LocalizedError {
    case notAuthenticated
    case tokenGenerationFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to create an invitation."

        case .tokenGenerationFailed:
            return "Unable to generate a secure invitation token."
        }
    }
}

// MARK: - SHA-256

private extension String {

    var sha256: String {
        let digest = SHA256.hash(
            data: Data(utf8)
        )

        return digest
            .map {
                String(format: "%02x", $0)
            }
            .joined()
    }
}
