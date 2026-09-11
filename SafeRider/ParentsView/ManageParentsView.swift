//
//  ManageParentsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 31/08/2025.
//

import SwiftUI

struct ManageParentsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddParent = false
    
    var body: some View {
        List {
            ForEach(dataManager.parents) { parent in
                VStack(alignment: .leading) {
                    Text(parent.motherName)
                        .font(.headline)
                    Text("Father: \(parent.fatherName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Email: \(parent.email)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Phone: \(parent.contactNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete(perform: deleteParent)
        }
        .navigationTitle("Manage Parents")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddParent = true }) {
                    Label("Add Parent", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddParent) {
            AddParentView()
                .environmentObject(dataManager)
        }
    }
    
    private func deleteParent(at offsets: IndexSet) {
        dataManager.deleteParents(at: offsets)
    }
}
