//
//  TransactionsView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Income.startDate, order: .reverse)
    private var incomes: [Income]

    @Query
    private var payments: [Payment]

    @Query(sort: \PaymentOccurrence.dueDate)
    private var occurrences: [PaymentOccurrence]

    @State private var selectedType = 0
    @State private var paymentFilter = 0
    @State private var selectedMonth = Date()
    @State private var selectedOccurrence: PaymentOccurrence?

    @State private var errorMessage: String?
    @State private var showError = false

    private let calendar = Calendar.current
    private let trLocale = Locale(identifier: "tr_TR")

    private var monthInterval: DateInterval? {
        calendar.dateInterval(
            of: .month,
            for: selectedMonth
        )
    }

    private var monthlyOccurrences: [PaymentOccurrence] {
        guard let interval = monthInterval else {
            return []
        }

        return occurrences.filter {
            interval.contains($0.dueDate)
        }
    }

    private var filteredOccurrences: [PaymentOccurrence] {
        monthlyOccurrences
            .filter {
                paymentFilter == 0 ? !$0.isPaid : $0.isPaid
            }
            .sorted {
                $0.dueDate < $1.dueDate
            }
    }

    private var totalAmount: Decimal {
        filteredOccurrences.reduce(.zero) {
            $0 + $1.amount
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                Picker("İşlem Türü", selection: $selectedType) {
                    Text("Gelirlerim").tag(0)
                    Text("Ödemelerim").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                monthSelector

                if selectedType == 0 {
                    incomeContent
                } else {
                    paymentContent
                }
            }
            .padding(.top, 12)
            .navigationTitle("İşlemlerim")
            .onAppear {
                generatePayments()
            }
            .onChange(of: selectedMonth) { _, _ in
                generatePayments()
            }
            .onChange(of: payments.count) { _, _ in
                generatePayments()
            }
            .sheet(item: $selectedOccurrence) { occurrence in
                PaymentOccurrenceEditView(
                    occurrence: occurrence
                )
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "İşlem tamamlanamadı.")
            }
        }
    }

    private var monthSelector: some View {
        HStack {

            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 40)
            }

            Spacer()

            Text(
                selectedMonth.formatted(
                    .dateTime.month(.wide).year()
                        .locale(trLocale)
                )
            )
            .font(.headline)

            Spacer()

            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 40)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var incomeContent: some View {

        let monthlyIncomes = incomes.flatMap { income in

            RecurrenceService.dates(
                in: selectedMonth,
                from: income.startDate,
                recurrence: RecurrenceType(
                    rawValue: income.recurrence
                ) ?? .once,
                endDate: income.endDate
            ).map { date in
                IncomeDisplayItem(
                    id: "\(income.id.uuidString)-\(date.timeIntervalSince1970)",
                    name: income.name,
                    amount: income.amount,
                    category: income.category,
                    date: date
                )
            }
        }
        .sorted { $0.date < $1.date }

        List {
            if monthlyIncomes.isEmpty {

                ContentUnavailableView(
                    "Gelir Bulunamadı",
                    systemImage: "tray",
                    description: Text(
                        "Bu aya ait gelir kaydı bulunmuyor."
                    )
                )

            } else {

                ForEach(monthlyIncomes) { income in

                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.left")
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(income.name)
                                .font(.subheadline.weight(.medium))

                            Text(income.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                income.date.formatted(
                                    .dateTime.day().month(.wide)
                                        .locale(trLocale)
                                )
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(formatCurrency(income.amount))
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 5)
                }

                Section {
                    totalRow(
                        title: "Toplam Gelir",
                        amount: monthlyIncomes.reduce(.zero) {
                            $0 + $1.amount
                        }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var paymentContent: some View {
        VStack(spacing: 0) {

            Picker("Ödeme Durumu", selection: $paymentFilter) {
                Text("Ödenmemiş").tag(0)
                Text("Ödenmiş").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {

                if filteredOccurrences.isEmpty {

                    ContentUnavailableView(
                        "Ödeme Bulunamadı",
                        systemImage: "checkmark.circle",
                        description: Text(
                            "Bu bölümde ödeme bulunmuyor."
                        )
                    )

                } else {

                    ForEach(filteredOccurrences) { occurrence in

                        HStack(spacing: 10) {

                            VStack(alignment: .leading, spacing: 5) {
                                Text(occurrence.name)
                                    .font(.subheadline.weight(.semibold))

                                Text(
                                    occurrence.dueDate.formatted(
                                        .dateTime.day().month(.wide)
                                            .locale(trLocale)
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                Text(formatCurrency(occurrence.amount))
                                    .font(.caption.weight(.medium))
                            }

                            Spacer(minLength: 4)

                            Button {
                                selectedOccurrence = occurrence
                            } label: {
                                Image(systemName: "pencil")
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)
                            .accessibilityLabel("Ödemeyi düzenle")

                            Button {
                                togglePaid(occurrence)
                            } label: {
                                Text(
                                    occurrence.isPaid
                                        ? "Geri Al"
                                        : "Ödendi"
                                )
                                .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(occurrence.isPaid ? .gray : .blue)
                        }
                        .padding(.vertical, 6)
                    }

                    Section {
                        totalRow(
                            title: paymentFilter == 0
                                ? "Toplam Bekleyen"
                                : "Toplam Ödenen",
                            amount: totalAmount
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func totalRow(
        title: String,
        amount: Decimal
    ) -> some View {

        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text(formatCurrency(amount))
                .font(.subheadline.weight(.bold))
        }
    }

    private func changeMonth(_ value: Int) {
        guard let next = calendar.date(
            byAdding: .month,
            value: value,
            to: selectedMonth
        ) else {
            return
        }

        selectedMonth = next
    }

    private func generatePayments() {
        do {
            try PaymentOccurrenceService.generateOccurrences(
                for: selectedMonth,
                context: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func togglePaid(_ occurrence: PaymentOccurrence) {

        occurrence.isPaid.toggle()

        occurrence.paidDate = occurrence.isPaid
            ? Date()
            : nil

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: "TRY")
                .locale(trLocale)
        )
    }
}

private struct IncomeDisplayItem: Identifiable {

    let id: String
    let name: String
    let amount: Decimal
    let category: String
    let date: Date
}
