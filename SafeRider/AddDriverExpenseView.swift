//
//  AddDriverExpenseView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 08/09/2026.
//

import SwiftUI

struct AddDriverExpenseView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var expenseName = ""
    @State private var expenseAmount = ""
    @State private var expenseDate = Date()

    var body: some View {
        Form {

            Section("Expense Information") {

                TextField(
                    "Expense Name",
                    text: $expenseName
                )

                TextField(
                    "Amount",
                    text: $expenseAmount
                )
                .keyboardType(.decimalPad)

                DatePicker(
                    "Date",
                    selection: $expenseDate,
                    displayedComponents: .date
                )
            }

            Section {
                Button {
                    saveExpense()
                } label: {
                    HStack {
                        Spacer()

                        Label(
                            "Save Expense",
                            systemImage: "checkmark.circle.fill"
                        )
                        .fontWeight(.semibold)

                        Spacer()
                    }
                }
                .foregroundStyle(SafeRiderTheme.orange)
                .disabled(!isValid)
            }
        }
        .scrollContentBackground(.hidden)
        .background(SafeRiderTheme.orangeTint)
        .navigationTitle("Add Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private var isValid: Bool {
        !expenseName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        && Double(expenseAmount) != nil
        && dataManager.currentDriver != nil
    }

    private func saveExpense() {
        guard let driver = dataManager.currentDriver else {
            return
        }

        let name = expenseName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !name.isEmpty,
              let amount = Double(expenseAmount)
        else {
            return
        }

        let expense = Expense(
            name: name,
            amount: amount,
            date: expenseDate,
            driverId: driver.id
        )

        dataManager.addExpense(expense)

        dismiss()
    }
}
