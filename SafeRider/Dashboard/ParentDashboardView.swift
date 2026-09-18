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
                    .navigationTitle("Manage Children")
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

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

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

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

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

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

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
                    .tint(
                        SafeRiderTheme.orange
                    )
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
        .sheet(
            isPresented: $showingAddChild
        ) {

            AddStudentView()
                .environmentObject(dataManager)
                .environmentObject(authManager)
        }
    }

    // MARK: - Child Summary Card

    @ViewBuilder
    private func childSummaryCard(
        _ child: Student
    ) -> some View {

        let schedule = transportationSchedule(
            for: child
        )

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            // MARK: - Child Information

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

            // MARK: - Schedule Status

            if let schedule {

                // Morning Pickup

                if let morningTime =
                    schedule.morningPickupTime {

                    HStack {

                        Label(
                            "Morning Pickup",
                            systemImage: "sunrise.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                        Spacer()

                        Text(
                            formattedTime(
                                morningTime
                            )
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            SafeRiderTheme.blue
                        )
                    }
                }

                // Afternoon Pickup

                if let afternoonTime =
                    schedule.afternoonPickupTime {

                    HStack {

                        Label(
                            "Afternoon Pickup",
                            systemImage: "sunset.fill"
                        )
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )

                        Spacer()

                        Text(
                            formattedTime(
                                afternoonTime
                            )
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            SafeRiderTheme.blue
                        )
                    }
                }

                // Active Status

                HStack {

                    Label(
                        schedule.isActive
                            ? "Transportation Active"
                            : "Transportation Inactive",
                        systemImage:
                            schedule.isActive
                            ? "checkmark.circle.fill"
                            : "pause.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        schedule.isActive
                            ? SafeRiderTheme.success
                            : SafeRiderTheme.secondaryText
                    )

                    Spacer()
                }

            } else {

                // No Schedule

                HStack(spacing: 8) {

                    Image(
                        systemName:
                            "calendar.badge.exclamationmark"
                    )
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )

                    Text(
                        "Transportation schedule not configured"
                    )
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        SafeRiderTheme.primaryText
                    )
                }
            }

            Divider()

            // MARK: - Transportation Schedule

            NavigationLink {

                ParentTransportationScheduleView(
                    student: child
                )

            } label: {

                HStack {

                    Image(
                        systemName:
                            "calendar.badge.clock"
                    )
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )

                    Text(
                        schedule == nil
                            ? "Set Transportation Schedule"
                            : "Manage Transportation Schedule"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)

                    Spacer()

                    Image(
                        systemName: "chevron.right"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
        .shadow(
            color: .black.opacity(0.07),
            radius: 6,
            y: 3
        )
    }

    // MARK: - Transportation Schedule Lookup

    private func transportationSchedule(
        for student: Student
    ) -> TransportationSchedule? {

        dataManager.transportationSchedules.first {
            $0.studentId == student.id
        }
    }

    // MARK: - Time Formatting

    private func formattedTime(
        _ date: Date
    ) -> String {

        date.formatted(
            date: .omitted,
            time: .shortened
        )
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

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {

                // Driver Info
                NavigationLink {
                    ParentDriverInfoView()
                } label: {
                    quickActionContent(
                        title: "Driver Info",
                        icon: "person.crop.rectangle.stack.fill"
                    )
                }
                .buttonStyle(.plain)

                // Tracking
                NavigationLink {
                    TransportationTrackingView()
                } label: {
                    quickActionContent(
                        title: "Tracking",
                        icon: "location.fill"
                    )
                }
                .buttonStyle(.plain)

                // Schedule
                NavigationLink {
                    ParentTransportationScheduleView()
                } label: {
                    quickActionContent(
                        title: "Schedule",
                        icon: "calendar.badge.clock"
                    )
                }
                .buttonStyle(.plain)

                // Payments
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
            quickActionContent(
                title: title,
                icon: icon
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func quickActionContent(
        title: String,
        icon: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    SafeRiderTheme.orange
                )

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
                .lineLimit(1)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 78,
            maxHeight: 78
        )
        .background(
            SafeRiderTheme.surface
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - Children

    @ViewBuilder
    private var parentChildrenView: some View {

        ZStack {

            SafeRiderTheme.orangeTint
                .ignoresSafeArea()

            if let parent =
                dataManager.currentParent {

                let children =
                    dataManager.students(
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

                                childDirectoryCard(
                                    child
                                )
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
                            .frame(
                                maxWidth: .infinity
                            )
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

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

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

                Image(
                    systemName: "chevron.right"
                )
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )
            }

            Divider()

            // MARK: Schedule Shortcut

            NavigationLink {

                ParentTransportationScheduleView(student: child)

            } label: {

                HStack {

                    Image(
                        systemName:
                            "calendar.badge.clock"
                    )
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )

                    Text(
                        transportationSchedule(
                            for: child
                        ) == nil
                        ? "Set Transportation Schedule"
                        : "Manage Transportation Schedule"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(.caption)
                }
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
            }
            .buttonStyle(.plain)
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

        if let parent =
            dataManager.currentParent {

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

        if let parent =
            dataManager.currentParent {

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
