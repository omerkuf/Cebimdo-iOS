
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
    @State private var amount: Decimal = .zero
    @State private var category = "Maaş"
    @State private var recurrence: RecurrenceType = .once
    @State private var selectedDate = Date()

    @State private var showSuccess = false
    @State private var showError = false

    private let backgroundColor = Color(
        red: 240 / 255.0,
        green: 248 / 255.0,
        blue: 245 / 255.0
    )

    private let primaryGreen = Color(
        red: 15 / 255.0,
        green: 122 / 255.0,
        blue: 67 / 255.0
    )

    private let lightGreen = Color(
        red: 230 / 255.0,
        green: 246 / 255.0,
        blue: 237 / 255.0
    )

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

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && amount > .zero
        && amount <= Decimal(99_999_999)
            + Decimal(string: "0.99")!
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
                    .tint(primaryGreen)
                    .onChange(of: selectedType) { _, newValue in
                        category = newValue == 0 ? "Maaş" : "Fatura"
                        name = ""
                        amount = .zero
                        recurrence = .once
                        selectedDate = Date()
                    }
                }
                .listRowBackground(Color.clear)

                Section("İşlem Bilgileri") {

                    VStack(alignment: .leading, spacing: 8) {
                        Text(
                            selectedType == 0
                                ? "Gelir Adı"
                                : "Ödeme Adı"
                        )
                        .font(.custom("AvenirNext-DemiBold", size: 14))

                        TextField(
                            selectedType == 0
                                ? "Örn. Maaş, Prim, Kira Geliri"
                                : "Örn. Kira, Elektrik, İnternet",
                            text: $name
                        )
                        .font(.custom("AvenirNext-Regular", size: 15))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(backgroundColor.opacity(0.65))
                        )
                    }
                    .padding(.vertical, 5)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tutar")
                            .font(.custom("AvenirNext-DemiBold", size: 14))

                        CurrencyAmountField(
                            title: "Tutar (₺)",
                            amount: $amount
                        )
                    }
                    .padding(.vertical, 5)

                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .font(.custom("AvenirNext-Medium", size: 15))
                    .tint(primaryGreen)
                    .padding(.vertical, 5)
                }
                .listRowBackground(Color.white)

                Section("Tekrarlama") {

                    VStack(alignment: .leading, spacing: 12) {

                        Text("Sıklık")
                            .font(.custom("AvenirNext-DemiBold", size: 14))

                        HStack(spacing: 4) {

                            recurrenceButton(
                                title: "Tek Seferlik",
                                type: .once
                            )

                            recurrenceButton(
                                title: "Aylık",
                                type: .monthly
                            )
                        }
                        .padding(4)
                        .background(
                            Capsule()
                                .fill(backgroundColor)
                        )
                    }
                    .padding(.vertical, 5)

                    DatePicker(
                        recurrence == .once
                            ? "İşlem Tarihi"
                            : "Başlangıç Tarihi",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .font(.custom("AvenirNext-Medium", size: 15))
                    .tint(primaryGreen)
                    .padding(.vertical, 5)
                }
                .listRowBackground(Color.white)

                Section {
                    Button {
                        saveTransaction()
                    } label: {
                        Text("Kaydet")
                            .font(.custom("AvenirNext-DemiBold", size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Capsule()
                                    .fill(
                                        canSave
                                            ? primaryGreen
                                            : Color.gray.opacity(0.35)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .listRowBackground(Color.clear)
                .listSectionSpacing(20)
            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Yeni İşlem")
            .tint(primaryGreen)
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
            }
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
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
        }
    }

    private func recurrenceButton(
        title: String,
        type: RecurrenceType
    ) -> some View {

        let isSelected = recurrence == type

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                recurrence = type
            }
        } label: {
            Text(title)
                .font(.custom("AvenirNext-DemiBold", size: 14))
                .foregroundStyle(
                    isSelected ? Color.white : primaryGreen
                )
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? primaryGreen
                                : Color.clear
                        )
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    private func saveTransaction() {

        guard canSave else {
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
                note: ""
            )

            modelContext.insert(income)

        } else {

            let payment = Payment(
                name: trimmedName,
                amount: amount,
                category: category,
                startDate: selectedDate,
                recurrence: recurrence,
                note: ""
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
        amount = .zero
        category = selectedType == 0 ? "Maaş" : "Fatura"
        selectedDate = Date()
        recurrence = .once
    }
}
