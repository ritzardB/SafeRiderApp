//
//  Untitled.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 08/09/2026.
//

import SwiftUI

struct DriverAddClientView: View {

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            List {

                // MARK: - Introduction

                Section {
                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {
                        Image(
                            systemName: "person.badge.plus"
                        )
                        .font(.system(size: 42))
                        .foregroundStyle(
                            SafeRiderTheme.blue
                        )

                        Text("Add a New Client")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        Text(
                            "Connect with a parent who wants you "
                            + "to provide transportation for their child."
                        )
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }
                    .padding(.vertical, 12)
                }

                // MARK: - How It Works

                Section("How It Works") {

                    Label(
                        "The parent provides an invitation token.",
                        systemImage: "1.circle.fill"
                    )

                    Label(
                        "Enter the invitation token here.",
                        systemImage: "2.circle.fill"
                    )

                    Label(
                        "Accept the connection request.",
                        systemImage: "3.circle.fill"
                    )

                    Label(
                        "The parent assigns their child to your ride.",
                        systemImage: "4.circle.fill"
                    )
                }

                // MARK: - Invitation

                Section {
                    NavigationLink {
                        DriverInvitationView()
                    } label: {
                        Label(
                            "Enter Invitation Token",
                            systemImage: "key.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("New Client")
    }
}
