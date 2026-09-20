//
//  ManageDriversView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 31/08/2025.
//

import SwiftUI

struct ManageDriversView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddDriver = false
    
    var body: some View {
        List {
            ForEach(dataManager.drivers) { driver in
                VStack(alignment: .leading) {
                    Text(driver.name)
                        .font(.headline)
                    Text("License: \(driver.licenseNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Vehicle: \(driver.vehicleNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Phone: \(driver.phoneNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete(perform: deleteDriver)
        }
        .navigationTitle("Manage Drivers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddDriver = true }) {
                    Label("Add Driver", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDriver) {
            AddDriverView()
                .environmentObject(dataManager)
        }
    }
    
    private func deleteDriver(at offsets: IndexSet) {
        dataManager.deleteDrivers(at: offsets)
    }
}
