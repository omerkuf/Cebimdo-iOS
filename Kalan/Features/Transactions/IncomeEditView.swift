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
    
    @State private var effectiveDate = Date()
    
    @Query private var incomeChanges: [IncomeAmountChange]

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
                    
                    DatePicker(
                        "Yeni Tutarın Geçerli Olacağı Tarih",
                        selection: $effectiveDate,
                        in: income.startDate...,
                        displayedComponents: .date
                    )

                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .disabled(true)
                }

                Section("Tekrarlama") {
                    Picker("Sıklık", selection: $recurrence) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .disabled(true)

                    DatePicker(
                        "Başlangıç Tarihi",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .disabled(true)
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
                        "Yeni gelir tutarı seçtiğiniz tarihten itibaren geçerli olur. " +
                        "Önceki dönemlerin gelir tutarları korunur."
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
        .onAppear {
            amount = IncomeHistoryService.amount(
                for: income,
                on: effectiveDate,
                changes: incomeChanges
            )
        }
        .onChange(of: effectiveDate) { _, newDate in
            amount = IncomeHistoryService.amount(
                for: income,
                on: newDate,
                changes: incomeChanges
            )
        }
    }

    private func saveChanges() {

        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty, amount > 0 else {
            return
        }

        let calendar = Calendar.current
        let effectiveDay = calendar.startOfDay(for: effectiveDate)

        let existingChange = incomeChanges.first {
            $0.incomeID == income.id &&
            calendar.isDate(
                $0.effectiveDate,
                inSameDayAs: effectiveDay
            )
        }

        // Income.amount başlangıç tutarı olarak korunuyor.
        // Güncel tutar, değişiklik geçmişinden hesaplanıyor.
        let previousAmount = IncomeHistoryService.amount(
            for: income,
            on: effectiveDay,
            changes: incomeChanges
        )

        if amount != previousAmount {

            if let existingChange {
                existingChange.amount = amount
            } else {
                let change = IncomeAmountChange(
                    incomeID: income.id,
                    effectiveDate: effectiveDay,
                    amount: amount
                )

                modelContext.insert(change)
            }
        }

        income.name = trimmedName
        income.category = category
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
