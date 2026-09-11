//
//  DriverInvitationView.swift
//  SafeRider
//
//  Driver invitation acceptance
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct DriverInvitationView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager

    // MARK: - State

    @State private var invitationToken = ""
    @State private var isAccepting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    // MARK: - Firebase

    private let db = Firestore.firestore()

    // MARK: - Body

    var body: some View {

        ZStack {

            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            ScrollView {

                VStack(spacing: 24) {

                    // MARK: Header

                    VStack(spacing: 12) {

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 54))
                            .foregroundStyle(
                                SafeRiderTheme.orange
                            )

                        Text("Driver Invitation")
                            .font(.title2.bold())
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        Text(
                            "Enter the invitation token provided by "
                            + "the parent to connect with their student."
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }

                    // MARK: Invitation Card

                    VStack(
                        alignment: .leading,
                        spacing: 16
                    ) {

                        Text("Invitation Token")
                            .font(.headline)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        TextField(
                            "Enter invitation token",
                            text: $invitationToken
                        )
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(
                            .system(
                                .body,
                                design: .monospaced
                            )
                        )
                        .padding()
                        .background(Color.white)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )

                        Text(
                            "Enter the token exactly as provided "
                            + "by the parent."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )

                        Button {

                            Task {
                                await acceptInvitation()
                            }

                        } label: {

                            HStack {

                                if isAccepting {

                                    ProgressView()
                                        .tint(.white)

                                } else {

                                    Image(
                                        systemName:
                                            "checkmark.circle.fill"
                                    )
                                }

                                Text(
                                    isAccepting
                                    ? "Accepting..."
                                    : "Accept Invitation"
                                )
                                .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(
                                canAcceptInvitation
                                ? SafeRiderTheme.orange
                                : SafeRiderTheme.secondaryText
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )
                        }
                        .disabled(
                            !canAcceptInvitation
                            || isAccepting
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                    )
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                    // MARK: Error

                    if let errorMessage {

                        messageCard(
                            icon:
                                "exclamationmark.triangle.fill",
                            text: errorMessage,
                            isError: true
                        )
                    }

                    // MARK: Success

                    if let successMessage {

                        messageCard(
                            icon:
                                "checkmark.circle.fill",
                            text: successMessage,
                            isError: false
                        )
                    }

                    // MARK: Information

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Label(
                            "How it works",
                            systemImage: "info.circle.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                        Text(
                            "1. The parent creates an invitation."
                        )

                        Text(
                            "2. The parent gives you the invitation token."
                        )

                        Text(
                            "3. Enter the token above."
                        )

                        Text(
                            "4. Accept the invitation."
                        )

                        Text(
                            "5. The student is assigned to your "
                            + "driver account."
                        )

                        Divider()

                        Text(
                            "Invitation tokens expire after 24 hours."
                        )
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding()
                    .background(
                        Color.white.opacity(0.85)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Invitation")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties

    private var canAcceptInvitation: Bool {

        !invitationToken
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    // MARK: - Message Card

    @ViewBuilder
    private func messageCard(
        icon: String,
        text: String,
        isError: Bool
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            Image(systemName: icon)
                .font(.headline)

            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .foregroundStyle(
            isError
            ? SafeRiderTheme.danger
            : SafeRiderTheme.success
        )
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            (
                isError
                ? SafeRiderTheme.danger
                : SafeRiderTheme.success
            )
            .opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }

    // MARK: - Accept Invitation

    private func acceptInvitation() async {

        // ---------------------------------------------------------
        // 1. Verify Firebase authentication
        // ---------------------------------------------------------

        guard let currentUser = Auth.auth().currentUser else {

            await MainActor.run {

                errorMessage =
                    "You must be signed in to accept an invitation."
            }

            return
        }

        // ---------------------------------------------------------
        // 2. Get SafeRider Driver profile
        // ---------------------------------------------------------

        guard let driver = dataManager.currentDriver else {

            await MainActor.run {

                errorMessage =
                    "Your driver profile is still loading. "
                    + "Please wait a moment and try again."
            }

            return
        }

        // ---------------------------------------------------------
        // 3. Normalize token
        // ---------------------------------------------------------

        let token =
            InvitationTokenHasher.normalize(
                invitationToken
            )

        guard !token.isEmpty else {

            await MainActor.run {

                errorMessage =
                    "Please enter an invitation token."
            }

            return
        }

        await MainActor.run {

            isAccepting = true
            errorMessage = nil
            successMessage = nil
        }

        defer {

            Task { @MainActor in
                isAccepting = false
            }
        }

        do {

            // -----------------------------------------------------
            // 4. Generate exactly the same SHA-256 hash used
            //    when the parent created the invitation.
            // -----------------------------------------------------

            let tokenHash =
                InvitationTokenHasher.hash(token)

            // -----------------------------------------------------
            // Diagnostic logging
            //
            // We deliberately do NOT print the actual token.
            // -----------------------------------------------------

            print(
                """
                [SafeRider Invitation]
                Token length: \(token.count)
                Token hash: \(tokenHash)
                """
            )

            // -----------------------------------------------------
            // 5. Find invitation by tokenHash ONLY
            //
            // We intentionally do NOT combine tokenHash and
            // status in the Firestore query.
            //
            // This avoids requiring a composite Firestore index
            // and allows us to distinguish:
            //
            // - hash mismatch
            // - already accepted invitation
            // - expired invitation
            // -----------------------------------------------------

            let snapshot = try await db
                .collection("driverInvitations")
                .whereField(
                    "tokenHash",
                    isEqualTo: tokenHash
                )
                .limit(to: 1)
                .getDocuments()

            print(
                """
                [SafeRider Invitation]
                Documents found by token hash:
                \(snapshot.documents.count)
                """
            )

            // -----------------------------------------------------
            // 6. Verify invitation exists
            // -----------------------------------------------------

            guard let invitationDocument =
                    snapshot.documents.first else {

                print(
                    """
                    [SafeRider Invitation]
                    HASH MISMATCH:
                    No Firestore invitation matched
                    the calculated token hash.
                    """
                )

                throw DriverInvitationAcceptanceError
                    .invalidToken
            }

            print(
                """
                [SafeRider Invitation]
                Invitation document found:
                \(invitationDocument.documentID)
                """
            )

            let invitationData =
                invitationDocument.data()

            // -----------------------------------------------------
            // 7. Verify invitation status
            // -----------------------------------------------------

            guard let status =
                    invitationData["status"] as? String else {

                throw DriverInvitationAcceptanceError
                    .invalidInvitation
            }

            print(
                """
                [SafeRider Invitation]
                Invitation status:
                \(status)
                """
            )

            guard status ==
                    DriverConnectionStatus
                        .pending
                        .rawValue else {

                if status ==
                    DriverConnectionStatus
                        .active
                        .rawValue {

                    throw DriverInvitationAcceptanceError
                        .alreadyAccepted
                }

                throw DriverInvitationAcceptanceError
                    .invalidToken
            }

            // -----------------------------------------------------
            // 8. Read Parent ID
            // -----------------------------------------------------

            guard
                let parentIdString =
                    invitationData["parentId"] as? String,

                let parentId =
                    UUID(
                        uuidString: parentIdString
                    )

            else {

                throw DriverInvitationAcceptanceError
                    .invalidInvitation
            }

            // -----------------------------------------------------
            // 9. Read Student ID
            // -----------------------------------------------------

            var studentId: UUID?

            if let studentIdString =
                invitationData["studentId"] as? String {

                studentId =
                    UUID(
                        uuidString: studentIdString
                    )
            }

            // -----------------------------------------------------
            // 10. Check expiration
            // -----------------------------------------------------

            guard
                let expiresTimestamp =
                    invitationData["expiresAt"]
                    as? Timestamp

            else {

                throw DriverInvitationAcceptanceError
                    .invalidInvitation
            }

            let expiresAt =
                expiresTimestamp.dateValue()

            print(
                """
                [SafeRider Invitation]
                Invitation expires:
                \(expiresAt)
                """
            )

            guard expiresAt > Date() else {

                throw DriverInvitationAcceptanceError
                    .expired
            }

            // -----------------------------------------------------
            // 11. Connection ID
            // -----------------------------------------------------

            let connectionId =
                UUID(
                    uuidString:
                        invitationDocument.documentID
                )
                ?? UUID()

            let acceptedAt = Date()

            // -----------------------------------------------------
            // 12. Create Driver Connection
            //
            // driverId:
            //     SafeRider Driver UUID
            //
            // driverAuthUID:
            //     Firebase Authentication UID
            // -----------------------------------------------------

            var connectionData: [String: Any] = [

                "id":
                    connectionId.uuidString,

                "parentId":
                    parentId.uuidString,

                "driverId":
                    driver.id.uuidString,

                "driverAuthUID":
                    currentUser.uid,

                "source":
                    DriverConnectionSource
                        .invitation
                        .rawValue,

                "status":
                    DriverConnectionStatus
                        .active
                        .rawValue,

                "createdAt":
                    invitationData["createdAt"]
                    ?? Timestamp(date: acceptedAt),

                "acceptedAt":
                    Timestamp(date: acceptedAt),

                "expiresAt":
                    expiresTimestamp
            ]

            if let studentId {

                connectionData["studentId"] =
                    studentId.uuidString
            }

            // -----------------------------------------------------
            // 13. Save Driver Connection
            // -----------------------------------------------------

            try await db
                .collection("driverConnections")
                .document(connectionId.uuidString)
                .setData(connectionData)

            print(
                """
                [SafeRider Invitation]
                Driver connection created:
                \(connectionId.uuidString)
                """
            )

            // -----------------------------------------------------
            // 14. Assign Student to Driver
            // -----------------------------------------------------

            if let studentId {

                let studentUpdate: [String: Any] = [

                    // SafeRider Driver UUID
                    "driverId":
                        driver.id.uuidString,

                    // Firebase Auth UID
                    "driverAuthUID":
                        currentUser.uid,

                    "updatedAt":
                        FieldValue.serverTimestamp()
                ]

                try await db
                    .collection("students")
                    .document(studentId.uuidString)
                    .updateData(studentUpdate)

                print(
                    """
                    [SafeRider Invitation]
                    Student assigned:
                    \(studentId.uuidString)
                    """
                )
            }

            // -----------------------------------------------------
            // 15. Mark invitation as accepted
            // -----------------------------------------------------

            let invitationUpdate: [String: Any] = [

                "status":
                    DriverConnectionStatus
                        .active
                        .rawValue,

                "driverId":
                    driver.id.uuidString,

                "driverAuthUID":
                    currentUser.uid,

                "acceptedAt":
                    Timestamp(date: acceptedAt)
            ]

            try await db
                .collection("driverInvitations")
                .document(
                    invitationDocument.documentID
                )
                .updateData(invitationUpdate)

            print(
                """
                [SafeRider Invitation]
                Invitation marked ACTIVE.
                """
            )

            // -----------------------------------------------------
            // 16. Success
            // -----------------------------------------------------

            await MainActor.run {

                successMessage =
                    "Invitation accepted successfully."

                invitationToken = ""
            }

            // Allow DataManager listeners time to receive
            // the student assignment.

            try? await Task.sleep(
                nanoseconds: 700_000_000
            )

            await MainActor.run {

                dismiss()
            }

        } catch let error
            as DriverInvitationAcceptanceError {

            await MainActor.run {

                errorMessage =
                    error.localizedDescription
            }

        } catch {

            // -----------------------------------------------------
            // IMPORTANT:
            //
            // Do not hide Firestore errors anymore.
            // This will tell us if the problem is:
            //
            // permission-denied
            // unavailable
            // failed-precondition
            // network error
            // etc.
            // -----------------------------------------------------

            print(
                """
                [SafeRider Invitation]
                FIRESTORE ERROR:
                \(error.localizedDescription)
                """
            )

            await MainActor.run {

                errorMessage =
                    "Unable to process the invitation: "
                    + error.localizedDescription
            }
        }
    }
}

// MARK: - Driver Invitation Acceptance Errors

private enum DriverInvitationAcceptanceError:
    LocalizedError {

    case invalidToken
    case invalidInvitation
    case expired
    case alreadyAccepted

    var errorDescription: String? {

        switch self {

        case .invalidToken:

            return """
            The invitation token could not be found.

            Please verify that you entered the token exactly
            as provided by the parent.
            """

        case .invalidInvitation:

            return """
            This invitation is incomplete or corrupted.

            Please ask the parent to create a new invitation.
            """

        case .expired:

            return """
            This invitation has expired.

            Please ask the parent to create a new invitation.
            """

        case .alreadyAccepted:

            return """
            This invitation has already been accepted.

            Please ask the parent to create a new invitation
            if another driver needs to be connected.
            """
        }
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        DriverInvitationView()
            .environmentObject(DataManager())
    }
}
