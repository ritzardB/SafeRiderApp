import SwiftUI

struct PaymentsView: View {
    @EnvironmentObject private var dataManager: DataManager

    let parentOnly: UUID?

    @State private var showingAddPayment = false
    @State private var paymentToDelete: Payment?

    init(parentOnly: UUID? = nil) {
        self.parentOnly = parentOnly
    }

    private var displayedPayments: [Payment] {
        let payments = dataManager.payments

        guard let parentOnly else {
            return payments.sorted {
                $0.date > $1.date
            }
        }

        return payments
            .filter {
                $0.parentId == parentOnly
            }
            .sorted {
                $0.date > $1.date
            }
    }
    private var totalPaid: Double {
        displayedPayments.reduce(0) {
            $0 + $1.amount
        }
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                summaryView
                tableHeaderView
                paymentHistoryView
            }
        }
        .navigationTitle("Payments")
        .toolbar {
            addPaymentButton
        }
        .sheet(
            isPresented: $showingAddPayment
        ) {
            NavigationStack {
                AddPaymentView()
            }
        }
        .alert(
            "Delete Payment?",
            isPresented: deleteAlertBinding
        ) {
            deleteAlertButtons
        } message: {
            deleteAlertMessage
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        SafeRiderTheme.orangeTint
            .ignoresSafeArea()
    }

    // MARK: - Summary

    private var summaryView: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text("Total Paid")
                    .font(.subheadline)
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )

                Text(
                    "AED \(totalPaid, specifier: "%.2f")"
                )
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    SafeRiderTheme.success
                )
            }

            Spacer()
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
        .padding()
    }

    // MARK: - Table Header

    private var tableHeaderView: some View {
        HStack(spacing: 12) {
            Text("Date")
                .frame(
                    width: 82,
                    alignment: .leading
                )

            Text("Child")
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            Text("Amount")
                .frame(
                    width: 95,
                    alignment: .trailing
                )
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(
            SafeRiderTheme.secondaryText
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            SafeRiderTheme.orangeTint
        )
    }

    // MARK: - Payment History

    @ViewBuilder
    private var paymentHistoryView: some View {
        if displayedPayments.isEmpty {
            ContentUnavailableView(
                "No Payments",
                systemImage: "creditcard",
                description: Text(
                    "Your payment history will appear here."
                )
            )
        } else {
            List {
                ForEach(displayedPayments) { payment in
                    paymentListRow(payment)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Payment Row

    private func paymentListRow(
        _ payment: Payment
    ) -> some View {
        NavigationLink {
            PaymentDetailsView(
                payment: payment
            )
        } label: {
            paymentRow(payment)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            SafeRiderTheme.surface
        )
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            Button(
                role: .destructive
            ) {
                paymentToDelete = payment
            } label: {
                Label(
                    "Delete",
                    systemImage: "trash"
                )
            }
        }
    }

    private func paymentRow(
        _ payment: Payment
    ) -> some View {
        let student = dataManager.students.first {
            $0.id == payment.studentId
        }

        return HStack(spacing: 12) {
            Text(
                formattedDate(payment.date)
            )
            .font(.caption)
            .foregroundStyle(
                SafeRiderTheme.secondaryText
            )
            .frame(
                width: 82,
                alignment: .leading
            )

            Text(
                student?.name ?? "Unknown"
            )
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(
                SafeRiderTheme.primaryText
            )
            .lineLimit(1)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            Text(
                formattedAmount(payment.amount)
            )
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(
                SafeRiderTheme.success
            )
            .frame(
                width: 95,
                alignment: .trailing
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Toolbar

    private var addPaymentButton: some ToolbarContent {
        ToolbarItem(
            placement: .topBarTrailing
        ) {
            Button {
                showingAddPayment = true
            } label: {
                Image(systemName: "plus")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.orange
                    )
            }
            .accessibilityLabel(
                "Add Payment"
            )
        }
    }

    // MARK: - Delete Alert

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: {
                paymentToDelete != nil
            },
            set: { newValue in
                if !newValue {
                    paymentToDelete = nil
                }
            }
        )
    }

    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button(
            "Delete",
            role: .destructive
        ) {
            confirmDelete()
        }

        Button(
            "Cancel",
            role: .cancel
        ) {
            paymentToDelete = nil
        }
    }

    private var deleteAlertMessage: Text {
        guard let payment = paymentToDelete else {
            return Text(
                "This payment will be deleted."
            )
        }

        return Text(
            "Delete the payment of "
            + formattedAmount(payment.amount)
            + "? This action cannot be undone."
        )
    }

    // MARK: - Formatting

    private func formattedDate(
        _ date: Date
    ) -> String {
        date.formatted(
            .dateTime
                .month(.abbreviated)
                .day()
                .year()
        )
    }

    private func formattedAmount(
        _ amount: Double
    ) -> String {
        String(
            format: "AED %.2f",
            amount
        )
    }

    // MARK: - Delete

    private func confirmDelete() {
        guard let payment = paymentToDelete else {
            return
        }

        paymentToDelete = nil

        dataManager.deletePayment(
            payment
        )
    }
}
