//
//  ParentSettingsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 09/09/2026.
//
import SwiftUI

struct ParentSettingsView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            List {
                Section("Security") {
                    NavigationLink {
                        ChangePasswordView()
                    } label: {
                        Label(
                            "Change Password",
                            systemImage: "key.fill"
                        )
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label {
                            Text("Notification Settings")
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(SafeRiderTheme.orange)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        HStack {
                            Spacer()

                            Label(
                                "Log Out",
                                systemImage:
                                    "rectangle.portrait.and.arrow.right"
                            )

                            Spacer()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Settings")
    }
}
