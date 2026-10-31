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
    @State private var errorMessage = ""
    
    @State private var editScope: PaymentEditScope = .onlyThis
    
    @Query private var payments: [Payment]
    
    private var isMonthlyPayment: Bool {
        guard let payment = payments.first(where: {
            $0.id == occurrence.paymentID
        }) else {
            return false
        }

        return RecurrenceType(rawValue: payment.recurrence) == .monthly
    }

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
                        .disabled(editScope == .thisAndFuture)

                    CurrencyAmountField(
                        title: "Tutar",
                        amount: $amount
                    )
                    .disabled(editScope == .thisAndFuture)

                    DatePicker(
                        "Ödeme Tarihi",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                    
                    if isMonthlyPayment {

                        Section("Değişiklik Kapsamı") {

                            ForEach(PaymentEditScope.allCases) { scope in

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
                                            editScope == scope ? .blue : .secondary
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

                            if editScope == .thisAndFuture {
                                Text("Bu seçenek yalnızca ödeme tarihini değiştirir. Ödenmiş kayıtlar korunur.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Text(
                        editScope == .onlyThis
                        ? "Değişiklikler yalnızca bu ödeme dönemini etkiler."
                        : "Ödeme tarihi bu ve sonraki dönemler için güncellenir. Geçmiş dönemler korunur."
                    )
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
                Text(errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
        }
    }

    private func saveChanges() {

        // Bu ve sonraki ödemeler seçildiyse
        if editScope == .thisAndFuture && isMonthlyPayment {

            do {
                try PaymentSeriesEditService.changeFutureDates(
                    occurrence: occurrence,
                    newDate: dueDate,
                    context: modelContext
                )

                dismiss()
            } catch {
                modelContext.rollback()
                errorMessage = error.localizedDescription
                showError = true
            }

            return
        }

        // Yalnızca bu ödeme seçildiyse
        occurrence.name = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        occurrence.amount = amount

        occurrence.dueDate = Calendar.current.startOfDay(
            for: dueDate
        )

        // scheduledDate değiştirilmiyor.
        // Böylece ödeme tekrar oluşturulmuyor.

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
