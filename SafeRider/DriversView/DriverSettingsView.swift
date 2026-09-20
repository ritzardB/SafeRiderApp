//
//  DriverSettingsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 20/09/2026.
//

import SwiftUI



struct DriverSettingsView: View {
    
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()
            
            
            Form {
                // MARK: - Profile
                
                
                
                Section("Profile") {
                    
                    NavigationLink {
                        if let driver = dataManager.currentDriver {
                            EditDriverProfileView(driver: driver)
                        } else {
                            Text("Driver profile is unavailable.")
                        }
                    } label: {
                        Label(
                            "Edit Profile",
                            systemImage: "person.crop.circle"
                        )
                    }
                    
                    NavigationLink {
                        if let driver = dataManager.currentDriver {
                            EditDriverVehicleView(driver: driver)
                        } else {
                            Text("Driver profile is unavailable.")
                        }
                    } label: {
                        Label(
                            "Vehicle Information",
                            systemImage: "car"
                        )
                    }
                    
                    // MARK: - Account Security
                    
                    Section("Account Security") {
                        NavigationLink {
                            ChangeDriverPasswordView()
                        } label: {
                            Label(
                                "Change Password",
                                systemImage: "lock"
                            )
                        }
                    }
                    
                    // MARK: - Preferences
                    
                    Section("Preferences") {
                        NavigationLink {
                            Text("Notification Preferences")
                        } label: {
                            Label(
                                "Notifications",
                                systemImage: "bell"
                            )
                        }
                    }
                    
                    // MARK: - About
                    
                    Section("About") {
                        HStack {
                            Text("App Version")
                            
                            Spacer()
                            
                            Text(
                                Bundle.main.infoDictionary?[
                                    "CFBundleShortVersionString"
                                ] as? String ?? "1.0"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
