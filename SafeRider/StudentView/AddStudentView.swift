import SwiftUI

struct AddStudentView: View {

    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var grade = ""
    @State private var section = ""
    @State private var school = ""
    @State private var teacherPhone = ""
    @State private var teacherName = ""
    @State private var driverId: UUID?

    var body: some View {

        NavigationStack {

            Form {

                Section("Student Info") {

                    TextField("Name", text: $name)

                    TextField("Grade", text: $grade)

                    TextField("Section", text: $section)

                    TextField("Teacher's Name", text: $teacherName)

                    TextField("Teacher's Phone", text: $teacherPhone)

                    TextField("School", text: $school)
                }

                Section("Transportation") {

                    Picker("Driver", selection: $driverId) {

                        Text("Unassigned")
                            .tag(nil as UUID?)

                        ForEach(dataManager.drivers) { driver in

                            Text(
                                driver.name.isEmpty
                                    ? driver.email
                                    : driver.name
                            )
                            .tag(driver.id as UUID?)
                        }
                    }

                    if let driverId,
                       let driver = dataManager.drivers.first(
                           where: { $0.id == driverId }
                       ) {

                        VStack(alignment: .leading, spacing: 4) {

                            Text("Assigned Driver")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                driver.name.isEmpty
                                    ? driver.email
                                    : driver.name
                            )
                            .font(.headline)

                            if !driver.vehicleNumber.isEmpty {

                                Text(
                                    "Vehicle: \(driver.vehicleNumber)"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Parent") {

                    if let parent = dataManager.currentParent {

                        VStack(alignment: .leading, spacing: 4) {

                            Text("Parent Account")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                parent.motherName.isEmpty
                                    ? parent.email
                                    : parent.motherName
                            )
                            .font(.headline)

                            Text(parent.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                    } else {

                        Text("Parent profile not available")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            .navigationTitle("Add Child")

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {
                        guard let parent = dataManager.currentParent else {
                            return
                        }

                        let selectedDriver = driverId.flatMap { selectedDriverId in
                            dataManager.drivers.first {
                                $0.id == selectedDriverId
                            }
                        }

                        let student = Student(
                            name: name,
                            grade: grade,
                            section: section,
                            teacherName: teacherName,
                            teacherPhone: teacherPhone,
                            parentId: parent.id,
                            driverId: selectedDriver?.id,
                            school: school
                        )

                        dataManager.addStudent(
                            student,
                            driverAuthUID: selectedDriver?.authUID
                        )

                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                        || grade.trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                        || dataManager.currentParent == nil
                    )
                }
            }
        }
    }
}
