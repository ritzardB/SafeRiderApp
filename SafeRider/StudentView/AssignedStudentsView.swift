import SwiftUI

struct NotificationMessage: Identifiable {
    let id = UUID()
    let text: String
}

struct AssignedStudentsView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var notificationMessage: NotificationMessage?

    var body: some View {
        ZStack {
            // MARK: - Full Background

            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            // MARK: - Content

            Group {
                if let driver = dataManager.currentDriver {
                    let assignedStudents = dataManager.students(for: driver)

                    if assignedStudents.isEmpty {
                        ContentUnavailableView(
                            "No Assigned Students",
                            systemImage: "person.2.slash",
                            description: Text(
                                "No students are currently assigned to this driver."
                            )
                        )
                    } else {
                        List(assignedStudents) { student in
                            VStack(alignment: .leading, spacing: 10) {

                                NavigationLink {
                                    StudentProfileView(student: student)
                                } label: {
                                    VStack(
                                        alignment: .leading,
                                        spacing: 6
                                    ) {
                                        Text(student.name)
                                            .font(.headline)
                                            .foregroundStyle(
                                                SafeRiderTheme.primaryText
                                            )

                                        Text(
                                            "Grade \(student.grade) - "
                                            + "Section \(student.section)"
                                        )
                                        .font(.subheadline)
                                        .foregroundStyle(
                                            SafeRiderTheme.secondaryText
                                        )

                                        Text(
                                            "School: \(student.school)"
                                        )
                                        .font(.subheadline)
                                        .foregroundStyle(
                                            SafeRiderTheme.secondaryText
                                        )

                                        if !student.teacherName.isEmpty {
                                            Text(
                                                "Teacher: "
                                                + "\(student.teacherName)"
                                            )
                                            .font(.subheadline)
                                            .foregroundStyle(
                                                SafeRiderTheme.secondaryText
                                            )
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }

                                Button {
                                    driverOnTheWay(for: student)
                                } label: {
                                    Label(
                                        "Driver On The Way",
                                        systemImage: "car.fill"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(SafeRiderTheme.orange)
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(
                                SafeRiderTheme.surface
                            )
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                } else {
                    ContentUnavailableView(
                        "Driver Profile Not Found",
                        systemImage: "car.fill",
                        description: Text(
                            "No driver profile is linked to this account."
                        )
                    )
                }
            }
        }
        .navigationTitle("Assigned Students")
        .alert(item: $notificationMessage) { message in
            Alert(
                title: Text("Ride Updated"),
                message: Text(message.text),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func driverOnTheWay(for student: Student) {
        guard let driver = dataManager.currentDriver else {
            return
        }

        dataManager.driverOnTheWay(
            student: student,
            driver: driver
        )

        notificationMessage = NotificationMessage(
            text:
                "The parent of \(student.name) has been notified "
                + "that you are on the way."
        )
    }
}
