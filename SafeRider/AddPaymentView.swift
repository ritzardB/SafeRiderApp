import SwiftUI

struct AddPaymentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStudentId: UUID?
    @State private var amountText = ""
    @State private var paymentDate = Date()
    @State private var note = ""

    private var currentParent: Parent? {
        dataManager.currentParent
    }

    private var children: [Student] {
        guard let parent = currentParent else {
            return []
        }

        return dataManager.students(for: parent)
    }

    private var selectedChild: Student? {
        guard let selectedStudentId else {
            return nil
        }

        return children.first {
            $0.id == selectedStudentId
        }
    }

    private var isValid: Bool {
        guard
            currentParent != nil,
            selectedStudentId != nil,
            let amount = Double(amountText),
            amount > 0
        else {
            return false
        }

        return true
    }

    var body: some View {
        Form {
            // MARK: - Parent

            Section("Parent") {
                if let parent = currentParent {
                    HStack(spacing: 12) {
                        ProfileAvatarView(
                            name: parentDisplayName(parent),
                            photoURL: parent.photoURL,
                            size: 46
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {
                            Text(parentDisplayName(parent))
                                .font(.headline)
                                .foregroundStyle(
                                    SafeRiderTheme.primaryText
                                )

                            if !parent.email.isEmpty {
                                Text(parent.email)
                                    .font(.caption)
                                    .foregroundStyle(
                                        SafeRiderTheme.secondaryText
                                    )
                            }
                        }

                        Spacer()

                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.success
                        )
                    }
                } else {
                    Text("Parent profile not available")
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                }
            }

            // MARK: - Child

            Section("Child") {
                if children.isEmpty {
                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {
                        Label(
                            "No children available",
                            systemImage: "person.2.slash"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )

                        Text(
                            "Add a child to your account before "
                            + "recording a payment."
                        )
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                    }
                } else {
                    Picker(
                        "Select Child",
                        selection: $selectedStudentId
                    ) {
                        Text("Select Child")
                            .tag(nil as UUID?)

                        ForEach(children) { child in
                            Text(child.name)
                                .tag(child.id as UUID?)
                        }
                    }

                    if let selectedChild {
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text("Selected Child")
                                .font(.caption)
                                .foregroundStyle(
                                    SafeRiderTheme.secondaryText
                                )

                            Text(selectedChild.name)
                                .font(.headline)
                                .foregroundStyle(
                                    SafeRiderTheme.primaryText
                                )

                            Text(
                                "Grade \(selectedChild.grade) • "
                                + "Section \(selectedChild.section)"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                        }
                        .padding(.top, 4)
                    }
                }
            }

            // MARK: - Payment

            Section("Payment") {
                TextField(
                    "Amount",
                    text: $amountText
                )
                .keyboardType(.decimalPad)

                DatePicker(
                    "Payment Date",
                    selection: $paymentDate,
                    displayedComponents: .date
                )

                TextField(
                    "Note",
                    text: $note,
                    axis: .vertical
                )
                .lineLimit(3...5)
            }

            // MARK: - Save

            Section {
                Button {
                    savePayment()
                } label: {
                    HStack {
                        Spacer()

                        Label(
                            "Save Payment",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .fontWeight(.semibold)

                        Spacer()
                    }
                }
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
                .disabled(!isValid)
            }
        }
        .scrollContentBackground(.hidden)
        .background(
            SafeRiderTheme.orangeTint
        )
        .navigationTitle("Add Payment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .cancellationAction
            ) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onAppear {
            setDefaultChild()
        }
    }

    // MARK: - Parent Name

    private func parentDisplayName(
        _ parent: Parent
    ) -> String {
        if !parent.motherName.isEmpty {
            return parent.motherName
        }

        if !parent.fatherName.isEmpty {
            return parent.fatherName
        }

        if !parent.email.isEmpty {
            return parent.email
        }

        return "Parent"
    }

    // MARK: - Default Child

    private func setDefaultChild() {
        guard selectedStudentId == nil else {
            return
        }

        if children.count == 1 {
            selectedStudentId = children.first?.id
        }
    }

    // MARK: - Save

    private func savePayment() {
        guard
            let parent = currentParent,
            let studentId = selectedStudentId,
            let amount = Double(amountText),
            amount > 0
        else {
            return
        }

        let cleanedNote = note.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let payment = Payment(
            parentId: parent.id,
            studentId: studentId,
            driverId: nil,
            amount: amount,
            date: paymentDate,
            note: cleanedNote.isEmpty
                ? nil
                : cleanedNote
        )

        dataManager.addPayment(payment)

        dismiss()
    }
}
