import SwiftUI

struct DriverExpensesView: View {
    @EnvironmentObject private var dataManager: DataManager

    @State private var showingAddExpense = false

    private var driverExpenses: [Expense] {
        guard let driver = dataManager.currentDriver else {
            return []
        }

        return dataManager.expenses
            .filter { $0.driverId == driver.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Table Header

            HStack {
                Text("Date")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Expense")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Amount")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(SafeRiderTheme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(SafeRiderTheme.orangeTint)

            Divider()

            // MARK: - Expense History

            if driverExpenses.isEmpty {

                ContentUnavailableView(
                    "No Expenses",
                    systemImage: "creditcard",
                    description: Text(
                        "Tap + to record your first expense."
                    )
                )

            } else {

                List {
                    ForEach(driverExpenses) { expense in

                        HStack(spacing: 12) {

                            Text(
                                expense.date.formatted(
                                    .dateTime
                                        .month(.abbreviated)
                                        .day()
                                        .year()
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(
                                SafeRiderTheme.secondaryText
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                            Text(expense.name)
                                .font(.headline)
                                .foregroundStyle(
                                    SafeRiderTheme.primaryText
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )

                            Text(
                                "AED \(expense.amount, specifier: "%.2f")"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                SafeRiderTheme.primaryText
                            )
                            .frame(
                                width: 100,
                                alignment: .trailing
                            )
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(SafeRiderTheme.background)
        .navigationTitle("Expenses")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .foregroundStyle(SafeRiderTheme.orange)
                }
                .accessibilityLabel("Add Expense")
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            NavigationStack {
                AddDriverExpenseView()
            }
        }
    }
}
