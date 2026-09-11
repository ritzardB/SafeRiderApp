//
//  DriverPaymentsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 08/09/2026.
//

import SwiftUI

struct DriverPaymentsView: View {
    @EnvironmentObject private var dataManager: DataManager

    @State private var showingAddPayment = false

    private var driverPayments: [Payment] {
        guard let driver = dataManager.currentDriver else {
            return []
        }

        return dataManager.payments
            .filter { $0.driverId == driver.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Table Header

            HStack(spacing: 12) {
                Text("Date")
                    .frame(width: 82, alignment: .leading)

                Text("Parent")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Child")
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Amount")
                    .frame(width: 90, alignment: .trailing)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(SafeRiderTheme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(SafeRiderTheme.orangeTint)

            Divider()

            // MARK: - Payment History

            if driverPayments.isEmpty {

                ContentUnavailableView(
                    "No Payments",
                    systemImage: "creditcard",
                    description: Text(
                        "Tap + to record your first payment."
                    )
                )

            } else {

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(driverPayments) { payment in
                            NavigationLink {
                                PaymentDetailsView(payment: payment)
                            } label: {
                                paymentRow(payment)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(SafeRiderTheme.background)
        .navigationTitle("Payments")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddPayment = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SafeRiderTheme.orange)
                }
                .accessibilityLabel("Add Payment")
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            NavigationStack {
                AddPaymentView()
            }
        }
    }

    // MARK: - Payment Row

    @ViewBuilder
    private func paymentRow(_ payment: Payment) -> some View {
        let parent = dataManager.parents.first {
            $0.id == payment.parentId
        }

        let student = dataManager.students.first {
            $0.id == payment.studentId
        }

        HStack(spacing: 12) {

            Text(
                payment.date.formatted(
                    .dateTime
                        .month(.abbreviated)
                        .day()
                        .year()
                )
            )
            .font(.caption)
            .foregroundStyle(SafeRiderTheme.secondaryText)
            .frame(
                width: 82,
                alignment: .leading
            )

            Text(parentName(parent))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(SafeRiderTheme.primaryText)
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            Text(student?.name ?? "Unknown")
                .font(.subheadline)
                .foregroundStyle(SafeRiderTheme.primaryText)
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            Text(
                "AED \(payment.amount, specifier: "%.2f")"
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(SafeRiderTheme.success)
            .frame(
                width: 90,
                alignment: .trailing
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func parentName(_ parent: Parent?) -> String {
        guard let parent else {
            return "Unknown"
        }

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
