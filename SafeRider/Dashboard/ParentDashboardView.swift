//
//  ParentDashboardView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 07/09/2026.
//

import SwiftUI

struct ParentDashboardView: View {

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var dataManager: DataManager

    @State private var selectedTab: ParentTab = .home
    @State private var showingAddChild = false

    enum ParentTab {
        case home
        case children
        case driver
        case payments
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Home

            NavigationStack {
                parentHomeView
                    .navigationTitle("My Dashboard")
            }
            .tabItem {
                Label(
                    "Home",
                    systemImage: "house.fill"
                )
            }
            .tag(ParentTab.home)

            // MARK: - Children

            NavigationStack {
                parentChildrenView
                    .navigationTitle("Children")
            }
            .tabItem {
                Label(
                    "Children",
                    systemImage: "person.2.fill"
                )
            }
            .tag(ParentTab.children)

            // MARK: - Driver

            NavigationStack {
                ParentDriverInvitationView()
                    .navigationTitle("Driver")
            }
            .tabItem {
                Label(
                    "Driver",
                    systemImage: "person.badge.plus"
                )
            }
            .tag(ParentTab.driver)

            // MARK: - Payments

            NavigationStack {
                parentPaymentsView
                    .navigationTitle("Payments")
            }
            .tabItem {
                Label(
                    "Payments",
                    systemImage: "creditcard.fill"
                )
            }
            .tag(ParentTab.payments)

            // MARK: - Profile

            NavigationStack {
                parentProfileTab
                    .navigationTitle("My Profile")
            }
            .tabItem {
                Label(
                    "Profile",
                    systemImage: "person.crop.circle.fill"
                )
            }
            .tag(ParentTab.profile)
        }
        .tint(SafeRiderTheme.orange)
    }

    // MARK: - Home

    @ViewBuilder
    private var parentHomeView: some View {
        ZStack {
            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            if let parent = dataManager.currentParent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        parentHeader(parent)
                        todaySection(parent)
                        quickActions
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Profile Not Found",
                    systemImage:
                        "person.crop.circle.badge.exclamationmark",
                    description: Text(
                        "Your account is authenticated, but no "
                        + "parent profile is linked to it yet."
                    )
                )
            }
        }
    }

    // MARK: - Parent Header

    @ViewBuilder
    private func parentHeader(_ parent: Parent) -> some View {
        HStack(spacing: 14) {
            ProfileAvatarView(
                name: parentDisplayName(parent),
                photoURL: parent.photoURL,
                size: 68
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome,")
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                Text(parentDisplayName(parent))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Text("SafeRider Parent")
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
            }

            Spacer()
        }
        .padding()
        .background(SafeRiderTheme.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .shadow(
            color: .black.opacity(0.07),
            radius: 6,
            y: 3
        )
    }

    // MARK: - Today's Transportation

    @ViewBuilder
    private func todaySection(
        _ parent: Parent
    ) -> some View {

        let children = dataManager.students(for: parent)

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Today's Transportation")
                    .font(.headline)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Spacer()

                Button("View All") {
                    selectedTab = .children
                }
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.orange
                )
            }

            if children.isEmpty {

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Image(
                        systemName: "person.2.slash"
                    )
                    .font(.title2)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                    Text("No children added yet")
                        .font(.headline)

                    Text(
                        "Add your child to begin managing "
                        + "their SafeRider transportation."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                    Button {
                        showingAddChild = true
                    } label: {
                        Label(
                            "Add Child",
                            systemImage:
                                "person.badge.plus"
                        )
                    }
                    .buttonStyle(
                        .borderedProminent
                    )
                    .tint(SafeRiderTheme.orange)
                }
                .padding()
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(
                    SafeRiderTheme.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

            } else {

                ForEach(children) { child in
                    childSummaryCard(child)
                }
            }
        }
    }

    // MARK: - Child Summary Card

    @ViewBuilder
    private func childSummaryCard(
        _ child: Student
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 12) {

                ProfileAvatarView(
                    name: child.name,
                    photoURL: child.photoURL,
                    size: 50
                )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(child.name)
                        .font(.headline)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                    Text(
                        "Grade \(child.grade) • "
                        + "Section \(child.section)"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }

                Spacer()
            }

            Divider()

            // MARK: Morning Pickup

            HStack {
                Label(
                    "Morning Pickup",
                    systemImage: "sunrise.fill"
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

                Spacer()

                Text(morningPickupTime)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        SafeRiderTheme.blue
                    )
            }

            // MARK: Afternoon Pickup

            HStack {
                Label(
                    "Afternoon Pickup",
                    systemImage: "sunset.fill"
                )
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

                Spacer()

                Text(afternoonPickupTime)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        SafeRiderTheme.blue
                    )
            }

            // MARK: Tracking

            NavigationLink {
                ParentTrackingView(student: child)
            } label: {
                Label(
                    "View Tracking",
                    systemImage: "location.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(SafeRiderTheme.blue)
        }
        .padding()
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .shadow(
            color: .black.opacity(0.07),
            radius: 6,
            y: 3
        )
    }

    // MARK: - Temporary Transportation Times

    /*
     These are temporary display values until the
     TransportationSchedule is connected to DataManager.

     Parent-configured values will eventually replace
     these helpers, for example:

         7:15 AM
         3:00 PM
     */

    private var morningPickupTime: String {
        "7:15 AM"
    }

    private var afternoonPickupTime: String {
        "3:00 PM"
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )

            HStack(spacing: 12) {

                quickAction(
                    title: "Children",
                    icon: "person.2.fill",
                    tab: .children
                )

                NavigationLink {
                    ParentTrackingView()
                } label: {

                    VStack(spacing: 8) {

                        Image(
                            systemName: "location.fill"
                        )
                        .font(.title3)
                        .foregroundStyle(
                            SafeRiderTheme.orange
                        )

                        Text("Tracking")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 72
                    )
                    .background(
                        SafeRiderTheme.surface
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                }
                .buttonStyle(.plain)

                quickAction(
                    title: "Payments",
                    icon: "creditcard.fill",
                    tab: .payments
                )
            }
        }
    }

    @ViewBuilder
    private func quickAction(
        title: String,
        icon: String,
        tab: ParentTab
    ) -> some View {

        Button {
            selectedTab = tab
        } label: {

            VStack(spacing: 8) {

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 72
            )
            .background(
                SafeRiderTheme.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Children

    @ViewBuilder
    private var parentChildrenView: some View {
        ZStack {

            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            if let parent = dataManager.currentParent {

                let children = dataManager.students(
                    for: parent
                )

                ScrollView {

                    LazyVStack(spacing: 12) {

                        ForEach(children) { child in

                            NavigationLink {
                                StudentProfileView(
                                    student: child
                                )
                            } label: {
                                childDirectoryCard(child)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            showingAddChild = true
                        } label: {

                            Label(
                                "Add Another Child",
                                systemImage:
                                    "person.badge.plus"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(
                            .borderedProminent
                        )
                        .tint(
                            SafeRiderTheme.orange
                        )
                        .padding(.top, 4)
                    }
                    .padding()
                }
            } else {

                ContentUnavailableView(
                    "Profile Not Found",
                    systemImage:
                        "person.crop.circle.badge.exclamationmark",
                    description: Text(
                        "Your parent profile could not be loaded."
                    )
                )
            }
        }
        .sheet(
            isPresented: $showingAddChild
        ) {
            AddStudentView()
                .environmentObject(dataManager)
                .environmentObject(authManager)
        }
    }

    // MARK: - Child Directory Card

    @ViewBuilder
    private func childDirectoryCard(
        _ child: Student
    ) -> some View {

        HStack(spacing: 12) {

            ProfileAvatarView(
                name: child.name,
                photoURL: child.photoURL,
                size: 50
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(child.name)
                    .font(.headline)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )

                Text(
                    "Grade \(child.grade) • "
                    + "Section \(child.section)"
                )
                .font(.subheadline)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

                if !child.school.isEmpty {
                    Text(child.school)
                        .font(.caption)
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
        }
        .padding()
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
    

    // MARK: - Payments

    @ViewBuilder
    private var parentPaymentsView: some View {

        if let parent = dataManager.currentParent {

            PaymentsView(
                parentOnly: parent.id
            )

        } else {

            ContentUnavailableView(
                "Profile Not Found",
                systemImage: "creditcard",
                description: Text(
                    "Your parent profile could not be loaded."
                )
            )
        }
    }

    // MARK: - Profile

    @ViewBuilder
    private var parentProfileTab: some View {

        if let parent = dataManager.currentParent {

            ParentProfileView(
                parent: parent
            )

        } else {

            ContentUnavailableView(
                "Profile Not Found",
                systemImage:
                    "person.crop.circle"
            )
        }
    }

    // MARK: - Helpers

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
}
