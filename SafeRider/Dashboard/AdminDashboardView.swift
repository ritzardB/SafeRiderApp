
//
//  AdminDashboardView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 28/08/2025.
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Manage Users")) {
                    NavigationLink("Manage Drivers") {
                        ManageDriversView()
                            .environmentObject(dataManager)
                    }
                    
                    NavigationLink("Manage Parents") {
                        ManageParentsView()
                            .environmentObject(dataManager)
                    }
                    
                    NavigationLink("Manage Students") {
                        ManageStudentsView()
                            .environmentObject(dataManager)
                    }
                    NavigationLink("Payments") {
                        PaymentsView()
                            .environmentObject(dataManager)
                    }
                }
                
                Section(header: Text("Rseports")) {
                    NavigationLink("Ride History Report") {
                        RideHistoryReportView()
                            .environmentObject(dataManager)
                    }
                    
                    NavigationLink("System Logs") {
                        SystemLogsView()
                            .environmentObject(dataManager)
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
        }
    }
}
