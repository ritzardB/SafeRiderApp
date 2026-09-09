import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showAdminLogin = false
    @State private var isSigningIn = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.green
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        Image("saferider")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 160)

                        Text("Login")
                            .font(.largeTitle.bold())

                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.emailAddress)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                if !email.isEmpty && !password.isEmpty {
                                    Task {
                                        await signIn()
                                    }
                                }
                            }

                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            focusedField = nil

                            Task {
                                await signIn()
                            }
                        } label: {
                            HStack {
                                if isSigningIn {
                                    ProgressView()
                                        .tint(.white)
                                }

                                Text(isSigningIn ? "Signing In…" : "Login")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                            password.isEmpty ||
                            isSigningIn
                        )

                        Button("Create an Account") {
                            focusedField = nil
                            showRegister = true
                        }

                        Spacer(minLength: 40)

                        Button("Admin Access") {
                            focusedField = nil
                            showAdminLogin = true
                        }
                        .font(.footnote)
                    }
                    .padding()
                    .frame(maxWidth: 500)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showAdminLogin) {
            AdminLoginView()
        }
    }

    @MainActor
    private func signIn() async {
        isSigningIn = true

        defer {
            isSigningIn = false
        }

        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)

        _ = await authManager.login(
            email: cleanEmail,
            password: password
        )
    }
}
