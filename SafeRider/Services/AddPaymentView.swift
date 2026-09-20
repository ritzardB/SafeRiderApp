import SwiftUI

struct AddPaymentView: View {

    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStudentId: UUID?
    @State private var selectedParentId: UUID?
    @State private var amountText = ""
    @State private var paymentDate = Date()
    @State private var note = ""

    // MARK: - Account Role

    private var isDriver: Bool {
        dataManager.currentDriver != nil
    }

    private var isParent: Bool {
        dataManager.currentParent != nil
    }

    // MARK: - Selected Parent

    private var selectedParent: Parent? {
        if isParent {
            return dataManager.currentParent
        }

        guard let selectedParentId else {
            return nil
        }

        return availableParents.first {
            $0.id == selectedParentId
        }
    }

    // MARK: - Available Parents

    private var availableParents: [Parent] {
        if isParent, let parent = dataManager.currentParent {
            return [parent]
        }

        if isDriver {
            return dataManager.parents
        }

        return []
    }

    // MARK: - Children

    private var children: [Student] {
        guard let parent = selectedParent else {
            return []
        }

        return dataManager.students(for: parent)
    }

    // MARK: - Selected Child

    private var selectedChild: Student? {
        guard let selectedStudentId else {
            return nil
        }

        return children.first {
            $0.id == selectedStudentId
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        guard
            selectedParent != nil,
            selectedChild != nil,
            let amount = Double(amountText),
            amount > 0
        else {
            return false
        }

        return true
    }

    // MARK: - Body

    var body: some View {
        Form {

            // MARK: - Parent

            Section("Parent") {

                if isParent {

                    if let parent = selectedParent {

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

                } else if isDriver {

                    if availableParents.isEmpty {

                        Text(
                            "No parents found for your assigned students."
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )

                    } else {

                        Picker(
                            "Select Parent",
                            selection: $selectedParentId
                        ) {

                            Text("Select a parent")
                                .tag(UUID?.none)

                            ForEach(availableParents) { parent in

                                Text(parentDisplayName(parent))
                                    .tag(Optional(parent.id))
                            }
                        }
                        .onChange(of: selectedParentId) { _, _ in

                            selectedStudentId = nil

                            if children.count == 1 {
                                selectedStudentId = children.first?.id
                            }
                        }
                    }

                } else {

                    Text("Parent selection is unavailable.")
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                }
            }

            // MARK: - Child

            Section("Child") {

                if selectedParent == nil {

                    Text("Please select a parent first.")
                        .font(.subheadline)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )

                } else if children.isEmpty {

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
                            "No children are currently associated "
                            + "with this parent."
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
                            systemImage: "checkmark.circle.fill"
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
        .background(SafeRiderTheme.orangeTint)
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

        if isParent,
           let parent = dataManager.currentParent {
            selectedParentId = parent.id
        }

        guard selectedStudentId == nil else {
            return
        }

        if children.count == 1 {
            selectedStudentId = children.first?.id
        }
    }

    // MARK: - Save Payment

    private func savePayment() {

        guard
            let parent = selectedParent,
            let student = selectedChild,
            let amount = Double(amountText),
            amount > 0
        else {
            return
        }

        let cleanedNote = note.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let driverId: UUID? = isDriver
            ? dataManager.currentDriver?.id
            : nil

        let payment = Payment(
            parentId: parent.id,
            studentId: student.id,
            driverId: driverId,
            amount: amount,
            date: paymentDate,
            note: cleanedNote.isEmpty ? nil : cleanedNote
        )

        dataManager.addPayment(payment)

        dismiss()
    }
}
