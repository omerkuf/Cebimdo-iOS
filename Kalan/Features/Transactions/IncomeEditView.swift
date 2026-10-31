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

    @Query private var incomeChanges: [IncomeAmountChange]
    @Query private var incomeOverrides: [IncomeOccurrenceOverride]

    @State private var name: String
    @State private var amount: Decimal
    @State private var category: String
    @State private var note: String
    @State private var effectiveDate: Date

    @State private var editScope: IncomeEditScope = .thisAndFuture
    @State private var showError = false
    @State private var errorMessage = ""

    private var isRecurring: Bool {
        RecurrenceType(rawValue: income.recurrence) != .once
    }

    init(income: Income, selectedDate: Date) {
        self.income = income

        _name = State(initialValue: income.name)
        _amount = State(initialValue: income.amount)
        _category = State(initialValue: income.category)
        _note = State(initialValue: income.note)
        _effectiveDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Gelir Bilgileri") {

                    TextField("Gelir Adı", text: $name)

                    CurrencyAmountField(
                        title: "Tutar (₺)",
                        amount: $amount
                    )

                    DatePicker(
                        "Geçerlilik Tarihi",
                        selection: $effectiveDate,
                        in: income.startDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)

                    HStack {
                        Text("Kategori")
                        Spacer()
                        Text(category)
                            .foregroundStyle(.secondary)
                    }
                }

                if isRecurring {
                    Section("Değişiklik Kapsamı") {

                        ForEach(IncomeEditScope.allCases) { scope in
                            Button {
                                editScope = scope
                            } label: {
                                HStack(spacing: 12) {

                                    Image(
                                        systemName: editScope == scope
                                        ? "largecircle.fill.circle"
                                        : "circle"
                                    )
                                    .foregroundStyle(
                                        editScope == scope
                                        ? Color.blue
                                        : Color.secondary
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scope.title)
                                            .font(.subheadline.weight(.medium))

                                        Text(scope.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Tekrarlama") {
                    HStack {
                        Text("Sıklık")
                        Spacer()
                        Text(
                            RecurrenceType(rawValue: income.recurrence)?
                                .title ?? "Tek Seferlik"
                        )
                        .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Başlangıç Tarihi")
                        Spacer()
                        Text(income.startDate, style: .date)
                            .foregroundStyle(.secondary)
                    }
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
                        !isRecurring || editScope == .onlyThis
                        ? "Tutar yalnızca seçilen gelir döneminde değişir."
                        : "Yeni tutar seçilen tarihten itibaren tüm dönemlere uygulanır. Sonraki tarihler için kaydedilmiş tutar değişikliklerinin üzerine yazılır."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Geliri Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Tamam") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .fontWeight(.semibold)
                }

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
                        ).isEmpty
                        || amount <= 0
                        || amount > Decimal(99_999_999)
                            + Decimal(string: "0.99")!
                    )
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
        }
        .onAppear {
            loadAmount()
        }
        .onChange(of: effectiveDate) { _, _ in
            loadAmount()
        }
    }

    private func loadAmount() {
        amount = IncomeHistoryService.amount(
            for: income,
            on: effectiveDate,
            changes: incomeChanges,
            overrides: incomeOverrides
        )
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

        do {
            if !isRecurring || editScope == .onlyThis {

                // Yalnızca bu gelir döneminin tutarı
                if let existing = incomeOverrides.first(where: {
                    $0.incomeID == income.id &&
                    calendar.isDate(
                        $0.occurrenceDate,
                        inSameDayAs: effectiveDay
                    )
                }) {
                    existing.amount = amount
                } else {
                    modelContext.insert(
                        IncomeOccurrenceOverride(
                            incomeID: income.id,
                            occurrenceDate: effectiveDay,
                            amount: amount
                        )
                    )
                }

            }
            else {
                
                IncomeSeriesEditService.updateThisAndFuture(
                    income: income,
                    effectiveDate: effectiveDay,
                    amount: amount,
                    changes: incomeChanges,
                    overrides: incomeOverrides,
                    context: modelContext
                )
            }

            income.name = trimmedName
            income.note = note

            try modelContext.save()
            dismiss()

        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

