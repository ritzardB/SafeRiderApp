import SwiftUI

struct RideHistoryReportView: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        List(dataManager.rides.sorted { $0.date > $1.date }) { ride in
            VStack(alignment: .leading, spacing: 4) {
                Text("Student: \(dataManager.student(for: ride)?.name ?? "Unknown")")
                Text("Driver: \(dataManager.driver(for: ride)?.name ?? "Unassigned")")
                Text("Status: \(ride.status.displayName)")
                Text(ride.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Ride History Report")
    }
}
