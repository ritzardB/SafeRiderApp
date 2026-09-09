import SwiftUI

struct DriverDashboardView: View {
    @EnvironmentObject private var dataManager: DataManager

    @State private var selectedTab: DriverTab = .home

    enum DriverTab {
        case home
        case tracking
        case newClient
        case expenses
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Home

            NavigationStack {
                driverHomeView
                    .navigationTitle("My Dashboard")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(DriverTab.home)

            // MARK: - Tracking

            NavigationStack {
                TrackingView()
            }
            .tabItem {
                Label("Tracking", systemImage: "car.fill")
            }
            .tag(DriverTab.tracking)

            // MARK: - New Client

            NavigationStack {
                DriverAddClientView()
            }
            .tabItem {
                Label("New", systemImage: "plus.circle.fill")
            }
            .tag(DriverTab.newClient)

            // MARK: - Expenses

            NavigationStack {
                DriverExpensesView()
            }
            .tabItem {
                Label("Expenses", systemImage: "creditcard.fill")
            }
            .tag(DriverTab.expenses)

            // MARK: - Profile

            NavigationStack {
                driverProfileView
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(DriverTab.profile)
        }
        .tint(SafeRiderTheme.orange)
    }

    // MARK: - Home

    private var driverHomeView: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ProfileAvatarView(
                        name: driverName,
                        photoURL: dataManager.currentDriver?.photoURL,
                        size: 72
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome, \(driverName)!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )

                        Text("Here's your SafeRider dashboard.")
                            .font(.subheadline)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            Section("Today's Operations") {
                NavigationLink {
                    AssignedStudentsView()
                } label: {
                    Label(
                        "Assigned Students",
                        systemImage: "person.2.fill"
                    )
                    .foregroundStyle(SafeRiderTheme.primaryText)
                }

                NavigationLink {
                    TrackingView()
                } label: {
                    Label(
                        "Ride Tracking",
                        systemImage: "car.fill"
                    )
                    .foregroundStyle(SafeRiderTheme.primaryText)
                }
            }

            Section("Client Management") {
                NavigationLink {
                    ParentsInformationView()
                } label: {
                    Label(
                        "Parent's Information",
                        systemImage: "person.2"
                    )
                    .foregroundStyle(SafeRiderTheme.primaryText)
                }

                NavigationLink {
                    DriverAddClientView()
                } label: {
                    Label(
                        "Add New Client",
                        systemImage: "person.badge.plus"
                    )
                    .foregroundStyle(SafeRiderTheme.orange)
                }
            }

            Section("Finance") {
                NavigationLink {
                    DriverPaymentsView()
                } label: {
                    Label(
                        "Payment Tracking",
                        systemImage: "creditcard.fill"
                    )
                    .foregroundStyle(SafeRiderTheme.primaryText)
                }

                NavigationLink {
                    DriverExpensesView()
                } label: {
                    Label(
                        "Expenses Tracking",
                        systemImage: "receipt.fill"
                    )
                    .foregroundStyle(SafeRiderTheme.primaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SafeRiderTheme.orangeTint)
    }

    // MARK: - Profile

    @ViewBuilder
    private var driverProfileView: some View {
        if let driver = dataManager.currentDriver {
            DriverProfileView(driver: driver)
        } else {
            ContentUnavailableView(
                "Profile Not Found",
                systemImage: "person.crop.circle",
                description: Text(
                    "No driver profile is linked to this account."
                )
            )
            .navigationTitle("Profile")
        }
    }

    // MARK: - Driver Name

    private var driverName: String {
        let name = dataManager.currentDriver?.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        return name.isEmpty ? "Driver" : name
    }
}
