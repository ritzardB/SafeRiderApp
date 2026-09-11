//
//  DriverInvitationView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 08/09/2026.
//

import SwiftUI

struct DriverInvitationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var invitationToken = ""

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            Form {

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(SafeRiderTheme.blue)

                        Text("Enter Invitation Token")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        Text(
                            "Enter the secure invitation token provided "
                            + "by the parent."
                        )
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }
                    .padding(.vertical, 8)
                }

                Section("Invitation") {
                    TextField(
                        "Invitation Token",
                        text: $invitationToken
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                }

                Section {
                    Button {
                        acceptInvitation()
                    } label: {
                        HStack {
                            Spacer()

                            Label(
                                "Accept Invitation",
                                systemImage: "checkmark.circle.fill"
                            )
                            .fontWeight(.semibold)

                            Spacer()
                        }
                    }
                    .foregroundStyle(SafeRiderTheme.orange)
                    .disabled(
                        invitationToken
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Invitation")
        .toolbar {
            ToolbarItem(
                placement: .cancellationAction
            ) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func acceptInvitation() {
        let token = invitationToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        // Firebase invitation validation will be implemented
        // in the Driver Connection milestone.
        print("Invitation token entered: \(token)")
    }
}
