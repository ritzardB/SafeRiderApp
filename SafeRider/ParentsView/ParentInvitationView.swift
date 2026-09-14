//
//  ParentInvitationView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 09/09/2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct ParentDriverInvitationView: View {
    @EnvironmentObject private var dataManager: DataManager

    @StateObject private var invitationManager =
        DriverInvitationManager()

    @State private var selectedStudentId: UUID?
    @State private var invitationToken: String?
    @State private var invitationExpiresAt: Date?
    @State private var invitationError: String?
    @State private var showingShareSheet = false

    private var children: [Student] {
        guard let parent = dataManager.currentParent else {
            return []
        }

        return dataManager.students(for: parent)
    }

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {

                    headerCard

                    childSelectionCard

                    if let invitationToken,
                       let invitationExpiresAt {
                        invitationCard(
                            token: invitationToken,
                            expiresAt: invitationExpiresAt
                        )
                    } else {
                        generateButton
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Invitation")
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                if invitationToken != nil {
                    Button("Reset") {
                        resetInvitation()
                    }
                }
            }
        }
        .alert(
            "Invitation Error",
            isPresented: Binding(
                get: {
                    invitationError != nil
                },
                set: { value in
                    if !value {
                        invitationError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(invitationError ?? "")
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Image(
                systemName: "person.badge.plus"
            )
            .font(.system(size: 42))
            .foregroundStyle(
                SafeRiderTheme.blue
            )

            Text("Invite a Driver")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            Text(
                "Create a secure invitation for a trusted "
                + "driver to provide transportation for your child."
            )
            .font(.subheadline)
            .foregroundStyle(
                SafeRiderTheme.secondaryText
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - Child Selection

    @ViewBuilder
    private var childSelectionCard: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Text("Select Child")
                    .font(.headline)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Spacer()

                if selectedStudentId != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                }
            }

            if children.isEmpty {
                VStack(spacing: 10) {
                    Image(
                        systemName: "person.2.slash"
                    )
                    .font(.system(size: 32))
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                    Text(
                        "Add a child before inviting a driver."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

            } else {
                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {
                    HStack(spacing: 14) {
                        ForEach(children) { child in
                            childInvitationCard(
                                child: child
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }

                if let selectedStudentId,
                   let selectedChild = children.first(
                        where: { $0.id == selectedStudentId }
                   ) {
                    HStack(spacing: 6) {
                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )

                        Text(
                            "\(selectedChild.name) selected"
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }
                } else {
                    Text(
                        "Tap a child to select them."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }
    
    // MARK: - Child Invitation Card

    private func childInvitationCard(
        child: Student
    ) -> some View {

        let isSelected =
            selectedStudentId == child.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedStudentId = child.id
            }
        } label: {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                HStack {
                    ProfileAvatarView(
                        name: child.name,
                        photoURL: child.photoURL,
                        size: 58
                    )

                    Spacer()

                    Image(
                        systemName: isSelected
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        isSelected
                            ? SafeRiderTheme.success
                            : SafeRiderTheme.secondaryText
                    )
                }

                Spacer(minLength: 2)

                Text(child.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Image(systemName: "graduationcap.fill")

                    Text(
                        "\(child.grade) • \(child.section)"
                    )
                }
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

                if !child.school.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "building.2.fill")

                        Text(child.school)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }
            }
            .padding(14)
            .frame(
                width: 220,
                height: 175,
                alignment: .leading
            )
            .background(
                isSelected
                    ? SafeRiderTheme.orangeTint
                    : SafeRiderTheme.surface
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    isSelected
                        ? SafeRiderTheme.orange
                        : Color.clear,
                    lineWidth: 2
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
            .shadow(
                color: .black.opacity(0.06),
                radius: 5,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate

    private var generateButton: some View {
        Button {
            Task {
                await generateInvitation()
            }
        } label: {
            HStack {
                Spacer()

                if invitationManager.isCreatingInvitation {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label(
                        "Generate Invitation",
                        systemImage: "qrcode"
                    )
                    .fontWeight(.semibold)
                }

                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(SafeRiderTheme.orange)
        .disabled(
            selectedStudentId == nil
            || dataManager.currentParent == nil
            || invitationManager.isCreatingInvitation
        )
    }

    // MARK: - Invitation

    private func invitationCard(
        token: String,
        expiresAt: Date
    ) -> some View {
        VStack(spacing: 16) {

            Text("Invitation Ready")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            Text("Scan this QR code")
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            if let image = makeQRCode(
                token: token
            ) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 220,
                        height: 220
                    )
                    .padding(12)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
            }

            Text("Invitation Token")
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            Text(formatToken(token))
                .font(
                    .system(
                        .title3,
                        design: .monospaced
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
                .textSelection(.enabled)
            
            let expirationInterval: TimeInterval = 24 * 60 * 60

            let expiresAt = Date().addingTimeInterval(expirationInterval)

            Text("Expires \(expirationInterval)")
                .font(.caption)
                .foregroundStyle(
                    SafeRiderTheme.danger
            )

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = token
                } label: {
                    Label(
                        "Copy Token",
                        systemImage: "doc.on.doc"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.bordered)
                .tint(SafeRiderTheme.blue)

                ShareLink(
                    item: invitationShareText(
                        token: token,
                        expiresAt: expiresAt
                    )
                ) {
                    Label(
                        "Share",
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.bordered)
                .tint(SafeRiderTheme.orange)
            }
        }
        .padding()
        .frame(
            maxWidth: .infinity
        )
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - Generate Invitation

    private func generateInvitation() async {
        guard
            let parent = dataManager.currentParent
        else {
            return
        }

        let result = await invitationManager
            .createInvitation(
                parent: parent,
                studentId: selectedStudentId
            )

        switch result {
        case .success(let invitation):
            invitationToken =
                invitation.token

            invitationExpiresAt =
                invitation.connection.expiresAt

        case .failure(let error):
            invitationError =
                error.localizedDescription
        }
    }

    // MARK: - QR Code

    private func makeQRCode(
        token: String
    ) -> UIImage? {
        let context = CIContext()
        let filter =
            CIFilter.qrCodeGenerator()

        filter.message = Data(
            "saferider://invite?token=\(token)"
                .utf8
        )

        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let transform = CGAffineTransform(
            scaleX: 10,
            y: 10
        )

        let scaledImage =
            outputImage.transformed(
                by: transform
            )

        guard let cgImage = context.createCGImage(
            scaledImage,
            from: scaledImage.extent
        ) else {
            return nil
        }

        return UIImage(
            cgImage: cgImage
        )
    }

    // MARK: - Token Formatting

    private func formatToken(_ token: String) -> String {
        token
    }

    // MARK: - Reset

    private func resetInvitation() {
        invitationToken = nil
        invitationExpiresAt = nil
        selectedStudentId = nil
    }
    
    private func invitationShareText(
        token: String,
        expiresAt: Date
    ) -> String {
        """
        SafeRider Driver Invitation

        Token: \(formatToken(token))

        This invitation expires at:
        \(expiresAt.formatted())
        """
    }
}


