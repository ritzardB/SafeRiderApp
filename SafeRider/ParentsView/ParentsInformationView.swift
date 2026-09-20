import SwiftUI

struct ParentsInformationView: View {

    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        List(uniqueParents) { parent in

            let children = dataManager.students(for: parent)

            Section {

                VStack(alignment: .leading, spacing: 12) {

                    // MARK: - Parent Information

                    HStack(spacing: 12) {

                        ProfileAvatarView(
                            name: parent.motherName.isEmpty
                                ? parent.fatherName
                                : parent.motherName,
                            photoURL: parent.photoURL,
                            size: 56
                        )

                        VStack(alignment: .leading, spacing: 4) {

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

                    // MARK: - Parent Details

                    if !parent.fatherName.isEmpty {
                        Label(
                            "Father: \(parent.fatherName)",
                            systemImage: "person"
                        )
                        .foregroundStyle(.primary)
                    }

                    if !parent.contactNumber.isEmpty {
                        Label(
                            parent.contactNumber,
                            systemImage: "phone"
                        )
                        .foregroundStyle(.primary)
                    }

                    // MARK: - Children

                    if children.isEmpty {

                        Label(
                            "No children assigned",
                            systemImage: "info.circle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    } else {

                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {

                            Text("Children (\(children.count))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                                .padding(.top, 4)

                            ForEach(children) { child in

                                NavigationLink {
                                    StudentProfileView(student: child)
                                } label: {

                                    HStack(spacing: 12) {

                                        // Child Profile Photo

                                        ProfileAvatarView(
                                            name: child.name,
                                            photoURL: child.photoURL,
                                            size: 44
                                        )

                                        // Child Details

                                        VStack(
                                            alignment: .leading,
                                            spacing: 3
                                        ) {

                                            Text(child.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

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

                                        Spacer(minLength: 4)
                                    }
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle())
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Parent's Information")
        .navigationBarTitleDisplayMode(.inline)
        .tint(.orange)
        .scrollContentBackground(.hidden)
        .background(Color.orange.opacity(0.10))
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
