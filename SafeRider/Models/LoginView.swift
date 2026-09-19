import SwiftUI

struct LoginView: View {

    // MARK: - Environment

    @EnvironmentObject private var authManager: AuthManager

    // MARK: - State

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var isSigningIn = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                SafeRiderTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        heroImage

                        welcomeSection

                        loginCard
                    }
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 35)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        Image("saferiderlogo_01")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 430)
            .frame(height: 250)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
            )
            .padding(.horizontal, 20)
            .padding(.top, 20)
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(spacing: 8) {
            Text("Welcome Back")
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(SafeRiderTheme.primaryText)

            Text("Sign in to continue your SafeRider journey.")
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(SafeRiderTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 22)
        .padding(.horizontal, 24)
    }

    // MARK: - Login Card

    private var loginCard: some View {
        VStack(spacing: 18) {

            emailField

            passwordField

            errorMessage

            loginButton

            registerButton
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
            color: .black.opacity(0.06),
            radius: 15,
            x: 0,
            y: 6
        )
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - Email Field

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Email")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SafeRiderTheme.primaryText)

            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(SafeRiderTheme.orange)

                TextField(
                    "Enter your email",
                    text: $email
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(SafeRiderTheme.surface)
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
                    SafeRiderTheme.orange.opacity(0.15),
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Password Field

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Password")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SafeRiderTheme.primaryText)

            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(SafeRiderTheme.orange)

                SecureField(
                    "Enter your password",
                    text: $password
                )
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    guard canSignIn else { return }

                    Task {
                        await signIn()
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(SafeRiderTheme.surface)
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
                    SafeRiderTheme.orange.opacity(0.15),
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Error Message

    @ViewBuilder
    private var errorMessage: some View {
        if let error = authManager.errorMessage {
            Text(error)
                .font(.footnote)
                .foregroundStyle(SafeRiderTheme.danger)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            focusedField = nil

            Task {
                await signIn()
            }
        } label: {
            HStack(spacing: 10) {
                if isSigningIn {
                    ProgressView()
                        .tint(.white)
                }

                Text(isSigningIn ? "Signing In…" : "Login")
            }
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(SafeRiderTheme.orange)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
        }
        .disabled(!canSignIn)
        .opacity(canSignIn ? 1 : 0.65)
    }

    // MARK: - Register Button

    private var registerButton: some View {
        Button {
            focusedField = nil
            showRegister = true
        } label: {
            Text("Create an Account")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SafeRiderTheme.orange)
        }
        .disabled(isSigningIn)
        .padding(.top, 2)
    }

    // MARK: - Validation

    private var canSignIn: Bool {
        !email.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && !password.isEmpty
        && !isSigningIn
    }

    // MARK: - Sign In

    @MainActor
    private func signIn() async {
        guard canSignIn else { return }

        isSigningIn = true

        defer {
            isSigningIn = false
        }

        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        _ = await authManager.login(
            email: cleanEmail,
            password: password
        )
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
