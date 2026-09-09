//
//  PaymentDetailsView.swift
//  SafeRider
//
//  Created by Richard Balabarcon on 08/09/2026.
//

import SwiftUI

struct PaymentDetailsView: View {
    @EnvironmentObject private var dataManager: DataManager

    let payment: Payment

    private var parent: Parent? {
        dataManager.parents.first {
            $0.id == payment.parentId
        }
    }

    private var student: Student? {
        dataManager.students.first {
            $0.id == payment.studentId
        }
    }

    private var driver: Driver? {
        dataManager.drivers.first {
            $0.id == payment.driverId
        }
    }

    var body: some View {
        List {
            Section("Payment") {
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(
                        "AED \(payment.amount, specifier: "%.2f")"
                    )
                    .fontWeight(.semibold)
                    .foregroundStyle(SafeRiderTheme.success)
                }

                HStack {
                    Text("Payment Date")
                    Spacer()
                    Text(
                        payment.date.formatted(
                            .dateTime
                                .month(.abbreviated)
                                .day()
                                .year()
                        )
                    )
                    .foregroundStyle(
                        SafeRiderTheme.secondaryText
                    )
                }
            }

            Section("Parent") {
                detailRow(
                    title: "Name",
                    value: parentName
                )

                if let email = parent?.email,
                   !email.isEmpty {
                    detailRow(
                        title: "Email",
                        value: email
                    )
                }

                if let phone = parent?.contactNumber,
                   !phone.isEmpty {
                    detailRow(
                        title: "Phone",
                        value: phone
                    )
                }
            }

            Section("Child") {
                detailRow(
                    title: "Name",
                    value: student?.name ?? "Unknown"
                )

                if let student {
                    if !student.grade.isEmpty {
                        detailRow(
                            title: "Grade",
                            value: student.grade
                        )
                    }

                    if !student.section.isEmpty {
                        detailRow(
                            title: "Section",
                            value: student.section
                        )
                    }

                    if !student.school.isEmpty {
                        detailRow(
                            title: "School",
                            value: student.school
                        )
                    }
                }
            }

            Section("Note") {
                if let note = payment.note,
                   !note.trimmingCharacters(
                       in: .whitespacesAndNewlines
                   ).isEmpty {
                    Text(note)
                        .foregroundStyle(
                            SafeRiderTheme.primaryText
                        )
                        .padding(.vertical, 4)
                } else {
                    Text("No note")
                        .foregroundStyle(
                            SafeRiderTheme.secondaryText
                        )
                }
            }

            if let driver {
                Section("Driver") {
                    detailRow(
                        title: "Name",
                        value: driver.name.isEmpty
                            ? "Driver"
                            : driver.name
                    )

                    if !driver.vehicleNumber.isEmpty {
                        detailRow(
                            title: "Vehicle",
                            value: driver.vehicleNumber
                        )
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(SafeRiderTheme.background)
        .navigationTitle("Payment Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var parentName: String {
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

    @ViewBuilder
    private func detailRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(
                    SafeRiderTheme.secondaryText
                )

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(
                    SafeRiderTheme.primaryText
                )
        }
    }
}
