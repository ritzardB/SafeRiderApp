import SwiftUI

struct ParentsInformationView: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        List(uniqueParents) { parent in
            let children = dataManager.students(for: parent)

            Section {
                VStack(alignment: .leading, spacing: 10) {

                    // MARK: Parent

                    HStack(spacing: 12) {
                        ProfileAvatarView(
                            name: parent.motherName.isEmpty
                                ? parent.fatherName
                                : parent.motherName,
                            photoURL: parent.photoURL,
                            size: 56
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(parentDisplayName(parent))
                                .font(.headline)

                            if !parent.email.isEmpty {
                                Text(parent.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    // MARK: Parent Details

                    if !parent.fatherName.isEmpty {
                        Label(
                            "Father: \(parent.fatherName)",
                            systemImage: "person"
                        )
                    }

                    if !parent.contactNumber.isEmpty {
                        Label(
                            parent.contactNumber,
                            systemImage: "phone"
                        )
                    }

                    // MARK: Children

                    if children.isEmpty {
                        Text("No children assigned")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Children (\(children.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)

                            ForEach(children) { child in
                                NavigationLink {
                                    StudentProfileView(student: child)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "person.fill")
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                            .frame(
                                                width: 36,
                                                height: 36
                                            )
                                            .background(
                                                Circle()
                                                    .fill(.blue.opacity(0.1))
                                            )

                                        VStack(
                                            alignment: .leading,
                                            spacing: 3
                                        ) {
                                            Text(child.name)
                                                .font(.headline)

                                            Text(
                                                "Grade \(child.grade) - "
                                                + "Section \(child.section)"
                                            )
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                            if !child.school.isEmpty {
                                                Text(
                                                    "School: \(child.school)"
                                                )
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Parent's Information")
    }

    // MARK: - Unique Parents

    private var uniqueParents: [Parent] {
        var seen = Set<UUID>()

        return dataManager.parents.filter { parent in
            seen.insert(parent.id).inserted
        }
    }

    // MARK: - Parent Display Name

    private func parentDisplayName(_ parent: Parent) -> String {
        if !parent.motherName.isEmpty {
            return parent.motherName
        }

        if !parent.fatherName.isEmpty {
            return parent.fatherName
        }

        return "Parent"
    }
}
