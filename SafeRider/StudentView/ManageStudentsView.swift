//
//  ManageStudentsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 31/08/2025.
//


import SwiftUI

struct ManageStudentsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddStudent = false
    
    var body: some View {
        List {
            ForEach(dataManager.students) { student in
                NavigationLink(destination: EditStudentView(student: student)
                    .environmentObject(dataManager)) {
                        VStack(alignment: .leading) {
                            Text(student.name)
                                .font(.headline)
                            Text("Grade \(student.grade) - Section \(student.section)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let parent = parentFor(student) {
                                Text("Parent: \(parent.motherName)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            } else {
                                Text("No parent assigned")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
            }
            .onDelete(perform: deleteStudent)
        }
        .navigationTitle("Manage Students")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddStudent = true }) {
                    Label("Add Student", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddStudent) {
            AddStudentView()
                .environmentObject(dataManager)
        }
    }
    
    // 🔹 Helper function
    private func parentFor(_ student: Student) -> Parent? {
        dataManager.parents.first(where: { $0.id == student.parentId })
    }
    
    private func deleteStudent(at offsets: IndexSet) {
        dataManager.deleteStudents(at: offsets)
    }
}
