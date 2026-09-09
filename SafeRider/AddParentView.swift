import SwiftUI

struct AddParentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var motherName = ""
    @State private var fatherName = ""
    @State private var email = ""
    @State private var contactNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent Info") {
                    TextField("Mother's Name", text: $motherName)
                    TextField("Father's Name", text: $fatherName)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone Number", text: $contactNumber)
                        .keyboardType(.phonePad)
                }

                Section {
                    Text("The parent must create an account through Firebase Authentication. This screen creates the application profile only.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Parent")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dataManager.addParent(Parent(
                            motherName: motherName,
                            fatherName: fatherName,
                            email: email,
                            contactNumber: contactNumber
                        ))
                        dismiss()
                    }
                    .disabled(motherName.isEmpty || email.isEmpty)
                }
            }
        }
    }
}
