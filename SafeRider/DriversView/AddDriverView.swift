import SwiftUI

struct AddDriverView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var licenseNumber = ""
    @State private var vehicleNumber = ""
    @State private var vehicleType = ""
    @State private var email = ""
    @State private var phoneNumber = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Driver Info") {
                    TextField("Name", text: $name)
                    TextField("License Number", text: $licenseNumber)
                    TextField("Vehicle Number", text: $vehicleNumber)
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section {
                    Text("Driver passwords are managed by Firebase Authentication and are never stored in the SafeRider profile.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Driver")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        dataManager.addDriver(Driver(
                            name: name,
                            licenseNumber: licenseNumber,
                            vehicleNumber: vehicleNumber,
                            vehicleType: vehicleType,
                            email: email,
                            phoneNumber: phoneNumber
                        ))
                        dismiss()
                    }
                    .disabled(name.isEmpty || licenseNumber.isEmpty || email.isEmpty)
                }
            }
        }
    }
}
