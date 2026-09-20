import SwiftUI

struct RegisterView: View {

    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var role: UserRole = .parent
    @State private var isPubliclyListed = false
    @State private var serviceArea = ""
    @State private var errorMessage = ""
    @State private var isRegistering = false

    var body: some View {
        ZStack {
            SafeRiderTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Hero Image

                    Image("saferiderlogo_01")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 430)
                        .frame(height: 220)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 28,
                                style: .continuous
                            )
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // MARK: - Header

                    VStack(spacing: 8) {
                        Text("Create Your Account")
                            .font(.system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundStyle(SafeRiderTheme.primaryText)

                        Text("Join SafeRider and make every journey safer.")
                            .font(.subheadline)
                            .foregroundStyle(SafeRiderTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)

                    // MARK: - Registration Card

                    VStack(spacing: 18) {

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SafeRiderTheme.primaryText)

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(SafeRiderTheme.orange)
                                    .frame(width: 20)

                                TextField(
                                    "Enter your email",
                                    text: $email
                                )
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(SafeRiderTheme.surface)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                                .stroke(
                                    SafeRiderTheme.orange.opacity(0.35),
                                    lineWidth: 1
                                )
                            }
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                            )
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SafeRiderTheme.primaryText)

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(SafeRiderTheme.orange)
                                    .frame(width: 20)

                                SecureField(
                                    "Create a password",
                                    text: $password
                                )
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(SafeRiderTheme.surface)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                                .stroke(
                                    SafeRiderTheme.orange.opacity(0.35),
                                    lineWidth: 1
                                )
                            }
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                            )
                        }

                        // MARK: - Account Type

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Account Type")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SafeRiderTheme.primaryText)

                            HStack(spacing: 12) {

                                roleButton(
                                    title: "Parent",
                                    icon: "figure.and.child.holdinghands",
                                    role: .parent
                                )

                                roleButton(
                                    title: "Driver",
                                    icon: "car.fill",
                                    role: .driver
                                )
                            }
                        }
                        
                        // MARK: - Driver Directory Visibility

                        if role == .driver {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Driver Directory Visibility")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SafeRiderTheme.primaryText)

                                Toggle(
                                    "Make my profile public",
                                    isOn: $isPubliclyListed
                                )
                                .tint(SafeRiderTheme.orange)

                                Text(
                                    isPubliclyListed
                                    ? "Parents can discover your driver profile."
                                    : "Your profile stays private and won't appear "
                                        + "in the public directory."
                                )
                                .font(.footnote)
                                .foregroundStyle(SafeRiderTheme.secondaryText)

                                if isPubliclyListed {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Service Area")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(SafeRiderTheme.primaryText)

                                        TextField(
                                            "e.g. Abu Dhabi, Khalifa City",
                                            text: $serviceArea
                                        )
                                        .textInputAutocapitalization(.words)
                                        .padding(.horizontal, 16)
                                        .frame(height: 52)
                                        .background(SafeRiderTheme.background)
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 14,
                                                style: .continuous
                                            )
                                        )
                                        .overlay {
                                            RoundedRectangle(
                                                cornerRadius: 14,
                                                style: .continuous
                                            )
                                            .stroke(
                                                SafeRiderTheme.orange.opacity(0.35),
                                                lineWidth: 1
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(14)
                            .background(SafeRiderTheme.background)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                            )
                        }

                        // MARK: - Error

                        if !errorMessage.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")

                                Text(errorMessage)
                                    .font(.footnote)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .foregroundStyle(SafeRiderTheme.danger)
                            .padding(12)
                            .background(
                                SafeRiderTheme.danger.opacity(0.08)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12,
                                    style: .continuous
                                )
                            )
                        }

                        // MARK: - Create Account Button

                        Button {
                            Task {
                                await register()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isRegistering {
                                    ProgressView()
                                        .tint(.white)

                                    Text("Creating Account…")
                                } else {
                                    Image(systemName: "person.badge.plus.fill")

                                    Text("Create Account")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                isFormValid
                                ? SafeRiderTheme.orange
                                : SafeRiderTheme.secondaryText.opacity(0.35)
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                            )
                        }
                        .disabled(!isFormValid || isRegistering)

                        // MARK: - Already Have Account

                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 5) {
                                Text("Already have an account?")

                                Text("Sign In")
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .foregroundStyle(SafeRiderTheme.blue)
                        }
                        .disabled(isRegistering)
                    }
                    .padding(20)
                    .background(SafeRiderTheme.surface)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24,
                            style: .continuous
                        )
                    )
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 18,
                        x: 0,
                        y: 8
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // MARK: - Footer

                    VStack(spacing: 5) {
                        Text("SafeRider")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(SafeRiderTheme.primaryText)

                        Text("SAFER JOURNEYS • BRIGHTER TOMORROWS")
                            .font(.caption2.weight(.semibold))
                            .tracking(1)
                            .foregroundStyle(SafeRiderTheme.secondaryText)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundStyle(SafeRiderTheme.blue)
            }
        }
    }

    // MARK: - Role Button

    @ViewBuilder
    private func roleButton(
        title: String,
        icon: String,
        role selection: UserRole
    ) -> some View {

        Button {
            role = selection
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(
                role == selection
                ? SafeRiderTheme.orange
                : SafeRiderTheme.secondaryText
            )
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                role == selection
                ? SafeRiderTheme.orange.opacity(0.10)
                : SafeRiderTheme.background
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    role == selection
                    ? SafeRiderTheme.orange
                    : SafeRiderTheme.secondaryText.opacity(0.20),
                    lineWidth: role == selection ? 2 : 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let hasEmail = !email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let hasPassword = !password.isEmpty

        let hasServiceArea = !serviceArea
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let isDriverDirectoryValid =
            role != .driver
            || !isPubliclyListed
            || hasServiceArea

        return hasEmail
            && hasPassword
            && isDriverDirectoryValid
    }

    // MARK: - Registration

    private func register() async {

        isRegistering = true
        errorMessage = ""

        defer {
            isRegistering = false
        }

        let result = await authManager.register(
            email: email.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            password: password,
            role: role
        )

        switch result {

        case .success:
            dismiss()

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthManager())
    }
}
