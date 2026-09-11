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

    // MARK: - Child

    private var childSelectionCard: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Child")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            if children.isEmpty {
                Text(
                    "Add a child before inviting a driver."
                )
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
            } else {
                Picker(
                    "Child",
                    selection: $selectedStudentId
                ) {
                    Text("Select Child")
                        .tag(nil as UUID?)

                    ForEach(children) { child in
                        Text(child.name)
                            .tag(child.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
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


