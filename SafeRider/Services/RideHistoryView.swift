import SwiftUI

struct RideHistoryView: View {
    let student: Student
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        List {
            let studentRides = dataManager.rides
                .filter { $0.studentId == student.id }
                .sorted { $0.date > $1.date }

            if studentRides.isEmpty {
                Text("No rides found for \(student.name).")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(studentRides) { ride in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Driver: \(dataManager.driver(for: ride)?.name ?? "Unassigned")")
                            .font(.subheadline)
                        Text("Status: \(ride.status.displayName)")
                            .font(.subheadline)
                        Text("Date: \(ride.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle("\(student.name)'s Rides")
    }
}
