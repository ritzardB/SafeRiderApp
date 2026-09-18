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

    @State private var homeAddress: String
    @State private var schoolAddress: String

    init(student: Student) {
        self.student = student

        _name = State(
            initialValue: student.name
        )

        _grade = State(
            initialValue: student.grade
        )

        _section = State(
            initialValue: student.section
        )

        _school = State(
            initialValue: student.school
        )

        _teacherPhone = State(
            initialValue: student.teacherPhone
        )

        _teacherName = State(
            initialValue: student.teacherName
        )

        _homeAddress = State(
            initialValue: student.homeAddress
        )

        _schoolAddress = State(
            initialValue: student.schoolAddress
        )
    }

    var body: some View {
        Form {
            // MARK: - Student Information

            Section("Student Information") {
                TextField(
                    "Name",
                    text: $name
                )

                TextField(
                    "Grade",
                    text: $grade
                )

                TextField(
                    "Section",
                    text: $section
                )
            }

            // MARK: - School Information

            Section("School Information") {
                TextField(
                    "School Name",
                    text: $school
                )

                TextField(
                    "Teacher's Name",
                    text: $teacherName
                )

                TextField(
                    "Teacher's Phone",
                    text: $teacherPhone
                )
                .keyboardType(.phonePad)
            }

            // MARK: - Student Addresses

            Section {
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Label(
                        "Home Address",
                        systemImage: "house.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)

                    TextField(
                        "Enter home address",
                        text: $homeAddress,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Label(
                        "School Address",
                        systemImage: "building.2.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)

                    TextField(
                        "Enter school address",
                        text: $schoolAddress,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }
            } header: {
                Text("Addresses")
            } footer: {
                Text(
                    "These addresses are used as the student's "
                    + "default transportation locations. "
                    + "Custom pickup or drop-off locations "
                    + "can be configured separately."
                )
            }
        }
        .navigationTitle("Edit Student")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .cancellationAction
            ) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(
                placement: .confirmationAction
            ) {
                Button("Save") {
                    saveStudent()
                }
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Save

    private func saveStudent() {
        let updatedStudent = Student(
            id: student.id,

            name: name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            grade: grade.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            section: section.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            teacherName: teacherName.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            teacherPhone: teacherPhone.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            parentId: student.parentId,
            driverId: student.driverId,

            school: school.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            photoURL: student.photoURL,

            homeAddress: homeAddress.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            homeLatitude: student.homeLatitude,
            homeLongitude: student.homeLongitude,

            schoolAddress: schoolAddress.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),

            schoolLatitude: student.schoolLatitude,
            schoolLongitude: student.schoolLongitude
        )

        dataManager.updateStudent(
            updatedStudent
        )

        dismiss()
    }
}
