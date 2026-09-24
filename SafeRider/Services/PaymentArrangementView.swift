//
//  PaymentArrangementView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 24/09/2026.
//

import SwiftUI

struct PaymentArrangementView: View {

    @EnvironmentObject private var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStudentId: UUID?
    @State private var paymentFrequency: PaymentFrequency = .monthly
    @State private var amountText = ""
    @State private var dueDay = Calendar.current.component(
        .day,
        from: Date()
    )
    @State private var dueWeekday = Calendar.current.component(
        .weekday,
        from: Date()
    )
    @State private var nextDueDate = Date()
    @State private var isActive = true

    @State private var isSaving = false
    @State private var showSaveConfirmation = false

    // MARK: - Parent

    private var parent: Parent? {
        dataManager.currentParent
    }

    // MARK: - Children

    private var children: [Student] {
        guard let parent else {
            return []
        }

        return dataManager.students(for: parent)
    }

    private var selectedChild: Student? {
        guard let selectedStudentId else {
            return nil
        }

        return children.first {
            $0.id == selectedStudentId
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        guard
            selectedChild != nil,
            let amount = Double(amountText),
            amount > 0
        else {
            return false
        }

        return true
    }

    // MARK: - Body

    var body: some View {

        Form {

            // MARK: Child

            Section("Child") {

                if children.isEmpty {

                    Text("No children available.")
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )

                } else {

                    Picker(
                        "Select Child",
                        selection: $selectedStudentId
                    ) {

                        Text("Select Child")
                            .tag(nil as UUID?)

                        ForEach(children) { child in

                            Text(child.name)
                                .tag(Optional(child.id))
                        }
                    }
                }
            }

            // MARK: Payment Frequency

            Section("Payment Frequency") {

                Picker(
                    "Frequency",
                    selection: $paymentFrequency
                ) {

                    ForEach(PaymentFrequency.allCases) { frequency in

                        Text(frequency.rawValue)
                            .tag(frequency)
                    }
                }

                // Weekly

                if paymentFrequency == .weekly {

                    Picker(
                        "Due Weekday",
                        selection: $dueWeekday
                    ) {

                        ForEach(1...7, id: \.self) { weekday in

                            Text(weekdayName(weekday))
                                .tag(weekday)
                        }
                    }
                }

                // Monthly

                if paymentFrequency == .monthly {

                    Picker(
                        "Due Day",
                        selection: $dueDay
                    ) {

                        ForEach(1...31, id: \.self) { day in

                            Text("Day \(day)")
                                .tag(day)
                        }
                    }
                }
            }

            // MARK: Amount

            Section("Payment Amount") {

                TextField(
                    "Amount (AED)",
                    text: $amountText
                )
                .keyboardType(.decimalPad)
            }

            // MARK: Due Date

            Section("Next Due Date") {

                DatePicker(
                    "Payment Date",
                    selection: $nextDueDate,
                    displayedComponents: .date
                )
            }

            // MARK: Status

            Section("Arrangement Status") {

                Toggle(
                    "Active",
                    isOn: $isActive
                )
            }

            // MARK: Save

            Section {

                Button {
                    saveArrangement()
                } label: {

                    HStack {

                        Spacer()

                        if isSaving {

                            ProgressView()

                        } else {

                            Label(
                                "Save Arrangement",
                                systemImage: "checkmark.circle.fill"
                            )
                            .fontWeight(.semibold)
                        }

                        Spacer()
                    }
                }
                .foregroundStyle(SafeRiderTheme.orange)
                .disabled(!isValid || isSaving)
            }
        }
        .scrollContentBackground(.hidden)
        .background(SafeRiderTheme.orangeTint)
        .navigationTitle("Payment Arrangement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setDefaultChild()
        }
        .alert(
            "Arrangement Saved",
            isPresented: $showSaveConfirmation
        ) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("The payment arrangement was saved successfully.")
        }
    }

    // MARK: - Default Child

    private func setDefaultChild() {

        guard selectedStudentId == nil else {
            return
        }

        if children.count == 1 {
            selectedStudentId = children.first?.id
        }
    }

    // MARK: - Weekday Name

    private func weekdayName(_ weekday: Int) -> String {

        let symbols = Calendar.current.weekdaySymbols

        guard (1...7).contains(weekday) else {
            return "Unknown"
        }

        return symbols[weekday - 1]
    }

    // MARK: - Save Arrangement

    private func saveArrangement() {

        guard
            let parent,
            let student = selectedChild,
            let amount = Double(amountText),
            amount > 0
        else {
            return
        }

        isSaving = true

        let arrangement = PaymentArrangement(
            parentId: parent.id,
            studentId: student.id,
            paymentFrequency: paymentFrequency,
            amount: amount,
            dueDay: paymentFrequency == .monthly
                ? dueDay
                : nil,
            dueWeekday: paymentFrequency == .weekly
                ? dueWeekday
                : nil,
            nextDueDate: nextDueDate,
            isActive: isActive
        )

        dataManager.savePaymentArrangement(arrangement)

        isSaving = false
        showSaveConfirmation = true
    }
}
