import SwiftUI

struct ChildrenListView: View {
    let parent: Parent
    @EnvironmentObject private var dataManager: DataManager
    @State private var showAddChild = false

    var body: some View {
        List {
            ForEach(dataManager.students(for: parent)) { child in
                VStack(alignment: .leading) {
                    Text(child.name).font(.headline)
                    Text("Grade: \(child.grade)").font(.subheadline)
                    Text("Section: \(child.section)").font(.subheadline)
                    Text("Teacher: \(child.teacherName)").font(.subheadline)
                    Text("Teacher's Phone: \(child.teacherPhone)")
                }
            }
        }
        .navigationTitle("My Children")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddChild = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showAddChild) {
            AddChildView(parent: parent)
                .environmentObject(dataManager)
        }
    }
}

struct AddChildView: View {
    let parent: Parent
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var grade = ""
    @State private var section = ""
    @State private var teacherName = ""
    @State private var teacherPhone = ""
    @State private var schoolName = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Child's Name", text: $name)
                TextField("Grade", text: $grade)
                TextField("Section", text: $section)
                TextField("Teacher's Name", text: $teacherName)
                TextField("Teacher's Phone", text: $teacherPhone)
                TextField("School Name", text: $schoolName)
            }
            .navigationTitle("Add Child")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Child") {
                        dataManager.addStudent(Student(
                            name: name,
                            grade: grade,
                            section: section,
                            teacherName: teacherName,
                            teacherPhone: teacherPhone,
                            parentId: parent.id,
                            driverId: nil,
                            school: schoolName
                        ))
                        dismiss()
                    }
                    .disabled(name.isEmpty || grade.isEmpty)
                }
            }
        }
    }
}
