import SwiftUI
import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SafeRiderApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var authManager = AuthManager()
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(dataManager)
                .preferredColorScheme(.light)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView("Loading SafeRider…")
            } else if let role = authManager.userRole {
                dashboard(for: role)
            } else {
                LoginView()
            }
        }
        .task(id: authManager.user?.uid) {
            syncSession()
        }
        .onChange(of: authManager.userRole) { _, _ in
            syncSession()
        }
    }

    private func syncSession() {
        guard let user = authManager.user, let role = authManager.userRole else {
            dataManager.syncAuthenticatedUser(uid: nil, email: nil, role: nil)
            return
        }
        dataManager.syncAuthenticatedUser(uid: user.uid, email: user.email, role: role)
    }

    @ViewBuilder
    private func dashboard(for role: UserRole) -> some View {
        switch role {
        case .parent:
            ParentDashboardView()
        case .driver:
            DriverDashboardView()
        case .admin:
            AdminDashboardView()
        }
    }
}
