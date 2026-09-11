import SwiftUI

struct EditStudentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    let student: Student
    @State private var name: String
    @State private var grade: String
    @State private var section: String
    @State private var school: String
    @State private var teacherPhone: String
    @State private var teacherName: String
    @State private var parentId: UUID?
    @State private var driverId: UUID?

    init(student: Student) {
        self.student = student
        _name = State(initialValue: student.name)
        _grade = State(initialValue: student.grade)
        _section = State(initialValue: student.section)
        _school = State(initialValue: student.school)
        _teacherPhone = State(initialValue: student.teacherPhone)
        _teacherName = State(initialValue: student.teacherName)
        _parentId = State(initialValue: student.parentId)
        _driverId = State(initialValue: student.driverId)
    }

    var body: some View {
        Form {
            Section("Student Info") {
                TextField("Name", text: $name)
                TextField("Grade", text: $grade)
                TextField("Section", text: $section)
                TextField("Teacher's Name", text: $teacherName)
                TextField("Teacher's Phone", text: $teacherPhone)
                TextField("School", text: $school)
            }

            Section("Assign to Parent") {
                Picker("Parent", selection: $parentId) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(dataManager.parents) { parent in
                        Text(parent.motherName.isEmpty ? parent.email : parent.motherName)
                            .tag(parent.id as UUID?)
                    }
                }
            }

            Section("Assign to Driver") {
                Picker("Driver", selection: $driverId) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(dataManager.drivers) { driver in
                        Text(driver.name).tag(driver.id as UUID?)
                    }
                }
            }
        }
        .navigationTitle("Edit Student")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    dataManager.updateStudent(Student(
                        id: student.id,
                        name: name,
                        grade: grade,
                        section: section,
                        teacherName: teacherName,
                        teacherPhone: teacherPhone,
                        parentId: parentId,
                        driverId: driverId,
                        school: school
                    ))
                    dismiss()
                }
            }
        }
    }
}
