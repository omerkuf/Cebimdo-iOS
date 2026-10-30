//
//  PaymentOccurrenceEditView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct PaymentOccurrenceEditView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let occurrence: PaymentOccurrence

    @State private var name: String
    @State private var amount: Decimal
    @State private var dueDate: Date
    @State private var showError = false

    init(occurrence: PaymentOccurrence) {
        self.occurrence = occurrence

        _name = State(initialValue: occurrence.name)
        _amount = State(initialValue: occurrence.amount)
        _dueDate = State(initialValue: occurrence.dueDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ödeme Bilgileri") {
                    TextField("Ödeme Adı", text: $name)

                    TextField(
                        "Tutar",
                        value: $amount,
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    DatePicker(
                        "Ödeme Tarihi",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                }

                Section {
                    Text("Değişiklikler yalnızca bu ödeme dönemini etkiler.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        saveChanges()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || amount <= 0
                    )
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Değişiklikler kaydedilemedi.")
            }
        }
    }

    private func saveChanges() {

        occurrence.name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        occurrence.amount = amount
        occurrence.dueDate = Calendar.current.startOfDay(
            for: dueDate
        )

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            showError = true
        }
    }
}
