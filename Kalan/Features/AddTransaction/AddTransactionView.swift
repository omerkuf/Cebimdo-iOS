//
//  AddTransactionView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {

    @Environment(\.modelContext) private var modelContext

    @Binding var selectedType: Int
    @State private var name = ""
    @State private var amountText = ""
    @State private var category = "Maaş"
    @State private var recurrence: RecurrenceType = .once
    @State private var selectedDate = Date()
    @State private var note = ""

    @State private var showSuccess = false
    @State private var showError = false

    private let incomeCategories = [
        "Maaş", "Prim / İkramiye", "Ek Gelir",
        "Kira Geliri", "Diğer"
    ]

    private let paymentCategories = [
        "Fatura", "Market", "Yemek", "Alışveriş",
        "Kira", "Kredi", "Abonelik", "Ulaşım", "Diğer"
    ]

    private var categories: [String] {
        selectedType == 0 ? incomeCategories : paymentCategories
    }

    private var parsedAmount: Decimal? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && (parsedAmount ?? .zero) > .zero
    }

    var body: some View {
        NavigationStack {
            Form {

                Section {
                    Picker("İşlem Türü", selection: $selectedType) {
                        Text("Gelir Ekle").tag(0)
                        Text("Ödeme Ekle").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: selectedType) { _, newValue in
                        category = newValue == 0 ? "Maaş" : "Fatura"
                        name = ""
                        amountText = ""
                        note = ""
                        recurrence = .once
                        selectedDate = Date()
                    }
                }

                Section("İşlem Bilgileri") {

                    TextField(
                        selectedType == 0 ? "Gelir Adı" : "Ödeme Adı",
                        text: $name
                    )

                    TextField("Tutar (₺)", text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
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
                        recurrence == .once
                            ? "İşlem Tarihi"
                            : "İlk İşlem Tarihi",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                }

                Section("Açıklama") {
                    TextField(
                        "Not (isteğe bağlı)",
                        text: $note,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                }

                Section {
                    Button {
                        saveTransaction()
                    } label: {
                        Text("Kaydet")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Yeni İşlem")
            .alert("Başarılı", isPresented: $showSuccess) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("İşlem başarıyla kaydedildi.")
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("İşlem kaydedilemedi. Tekrar deneyin.")
            }
        }
    }

    private func saveTransaction() {

        guard canSave, let amount = parsedAmount else {
            return
        }

        let trimmedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if selectedType == 0 {

            let income = Income(
                name: trimmedName,
                amount: amount,
                category: category,
                startDate: selectedDate,
                recurrence: recurrence,
                note: note
            )

            modelContext.insert(income)

        } else {

            let payment = Payment(
                name: trimmedName,
                amount: amount,
                category: category,
                startDate: selectedDate,
                recurrence: recurrence,
                note: note
            )

            modelContext.insert(payment)

        }

        do {
            try modelContext.save()
            resetFields()
            showSuccess = true
        } catch {
            modelContext.rollback()
            print("SwiftData save error: \(error)")
            showError = true
        }
    }

    private func resetFields() {
        name = ""
        amountText = ""
        note = ""
        selectedDate = Date()
        recurrence = .once
    }
}
