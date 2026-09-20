import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var userRole: UserRole?
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        user = Auth.auth().currentUser
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self else { return }
                self.user = user
                self.isLoading = true

                guard let user else {
                    self.userRole = nil
                    self.isLoading = false
                    return
                }

                await self.fetchUserRole(uid: user.uid)
            }
        }
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    func register(email: String, password: String, role: UserRole) async -> Result<User, Error> {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user

            try await db.collection("users").document(user.uid).setData([
                "email": email,
                "role": role.rawValue,
                "createdAt": FieldValue.serverTimestamp()
            ])

            // Application profiles are created by DataManager using the model UUID.
            // Firebase Authentication remains the source of truth for credentials.
            userRole = role
            errorMessage = nil
            return .success(user)
        } catch {
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    func login(email: String, password: String) async -> Result<User, Error> {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = result.user
            await fetchUserRole(uid: user.uid)

            guard userRole != nil else {
                let error = AuthError.missingRole
                try? Auth.auth().signOut()
                errorMessage = error.localizedDescription
                return .failure(error)
            }

            errorMessage = nil
            return .success(user)
        } catch {
            errorMessage = error.localizedDescription
            return .failure(error)
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        user = nil
        userRole = nil
    }

    private func fetchUserRole(uid: String) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()

            guard let roleString = snapshot.data()?["role"] as? String else {
                print("⚠️ SafeRider: No role found for UID: \(uid)")
                userRole = nil
                isLoading = false
                return
            }

            print("✅ SafeRider: Firebase role = \(roleString)")
            userRole = UserRole(rawValue: roleString)

        } catch {
            let nsError = error as NSError

            print("""
            🔴 SafeRider Firebase Auth/Firestore Error
            Domain: \(nsError.domain)
            Code: \(nsError.code)
            Description: \(nsError.localizedDescription)
            UserInfo: \(nsError.userInfo)
            """)

            errorMessage = nsError.localizedDescription
            userRole = nil
        }

        isLoading = false
    }
}

enum AuthError: LocalizedError {
    case missingRole

    var errorDescription: String? {
        switch self {
        case .missingRole:
            return "Your account has no SafeRider role. Please contact an administrator."
        }
    }
}
