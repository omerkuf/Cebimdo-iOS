//
//  EditPaymentView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI

struct EditPaymentView: View {

    @Environment(\.dismiss) private var dismiss

    @State var payment: DemoPayment

    let onSave: (DemoPayment) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Ödeme Bilgileri") {

                    TextField(
                        "Ödeme Adı",
                        text: $payment.name
                    )

                    TextField(
                        "Tutar",
                        value: $payment.amount,
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    DatePicker(
                        "Ödeme Tarihi",
                        selection: $payment.dueDate,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("Ödemeyi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        payment.name = payment.name
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        onSave(payment)
                        dismiss()
                    }
                    .disabled(
                        payment.name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || payment.amount <= 0
                    )
                }
            }
        }
    }
}
