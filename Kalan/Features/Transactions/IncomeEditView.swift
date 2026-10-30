//
//  IncomeEditView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct IncomeEditView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let income: Income

    @State private var name: String
    @State private var amount: Decimal
    @State private var category: String
    @State private var startDate: Date
    @State private var recurrence: RecurrenceType
    @State private var note: String

    @State private var showError = false

    private let categories = [
        "Maaş",
        "Prim / İkramiye",
        "Ek Gelir",
        "Kira Geliri",
        "Diğer"
    ]

    init(income: Income) {
        self.income = income

        _name = State(initialValue: income.name)
        _amount = State(initialValue: income.amount)
        _category = State(initialValue: income.category)
        _startDate = State(initialValue: income.startDate)
        _recurrence = State(
            initialValue: RecurrenceType(
                rawValue: income.recurrence
            ) ?? .once
        )
        _note = State(initialValue: income.note)
    }

    var body: some View {
        NavigationStack {
            Form {

                Section("Gelir Bilgileri") {
                    TextField("Gelir Adı", text: $name)

                    TextField(
                        "Tutar",
                        value: $amount,
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }

                Section("Tekrarlama") {
                    Picker("Sıklık", selection: $recurrence) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }

                    DatePicker(
                        "Başlangıç Tarihi",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                }

                Section("Açıklama") {
                    TextField(
                        "Not",
                        text: $note,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }

                Section {
                    Text(
                        "Bu değişiklik gelir tanımını günceller. " +
                        "Tekrarlayan gelirlerde geçmiş dönemler de " +
                        "yeniden hesaplanabilir."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Geliri Düzenle")
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
                Text("Gelir güncellenemedi.")
            }
        }
    }

    private func saveChanges() {
        income.name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        income.amount = amount
        income.category = category
        income.startDate = startDate
        income.recurrence = recurrence.rawValue
        income.note = note

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            showError = true
        }
    }
}
