//
//  DashboardView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Binding var selectedTab: AppTab
    @Binding var selectedAddType: Int

    @Environment(\.modelContext) private var modelContext

    @Query private var incomes: [Income]
    @Query private var payments: [Payment]

    @Query(sort: \PaymentOccurrence.dueDate)
    private var occurrences: [PaymentOccurrence]

    @State private var selectedOccurrence: PaymentOccurrence?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSettings = false
    
    @AppStorage("salaryDay")
    private var salaryDay = 15

    private let calendar = Calendar.current
    private let trLocale = Locale(identifier: "tr_TR")

    private var currentMonth: Date {
        Date()
    }

    private var monthlyOccurrences: [PaymentOccurrence] {
        guard let interval = calendar.dateInterval(
            of: .month,
            for: currentMonth
        ) else {
            return []
        }

        return occurrences.filter {
            interval.contains($0.dueDate)
        }
    }

    private var monthlyIncome: Decimal {
        DashboardCalculator.monthlyIncome(
            incomes: incomes,
            month: currentMonth
        )
    }

    private var monthlyPaid: Decimal {
        DashboardCalculator.monthlyPaid(
            occurrences: monthlyOccurrences
        )
    }

    private var monthlyUnpaid: Decimal {
        DashboardCalculator.monthlyUnpaid(
            occurrences: monthlyOccurrences
        )
    }

    private var remainingBudget: Decimal {
        DashboardCalculator.remainingBudget(
            income: monthlyIncome,
            occurrences: monthlyOccurrences
        )
    }

    private var upcomingPayments: [PaymentOccurrence] {

        let today = calendar.startOfDay(for: Date())

        guard let endDate = calendar.date(
            byAdding: .day,
            value: 30,
            to: today
        ) else {
            return []
        }

        return occurrences
            .filter {
                !$0.isPaid &&
                calendar.startOfDay(for: $0.dueDate) <= endDate
            }
            .sorted {
                $0.dueDate < $1.dueDate
            }
    }
    
    private var salaryPeriodStart: Date {
        BudgetCalculator.previousSalaryDate(
            salaryDay: salaryDay
        )
    }

    private var salaryPeriodEnd: Date {
        BudgetCalculator.nextSalaryDate(
            salaryDay: salaryDay
        )
    }

    private var daysUntilSalary: Int {
        BudgetCalculator.daysUntilSalary(
            salaryDay: salaryDay
        )
    }

    private var periodOccurrences: [PaymentOccurrence] {
        occurrences.filter {
            $0.dueDate >= salaryPeriodStart &&
            $0.dueDate < salaryPeriodEnd
        }
    }

    private var periodIncome: Decimal {
        incomes.reduce(.zero) { total, income in

            let recurrence = RecurrenceType(
                rawValue: income.recurrence
            ) ?? .once

            let months = [
                salaryPeriodStart,
                salaryPeriodEnd
            ]

            let dates = months.flatMap { month in
                RecurrenceService.dates(
                    in: month,
                    from: income.startDate,
                    recurrence: recurrence,
                    endDate: income.endDate
                )
            }

            let matchingDates = dates.filter {
                $0 >= salaryPeriodStart &&
                $0 < salaryPeriodEnd
            }

            return total + income.amount * Decimal(matchingDates.count)
        }
    }

    private var periodRemainingBudget: Decimal {
        let totalPayments = periodOccurrences.reduce(.zero) {
            $0 + $1.amount
        }

        return periodIncome - totalPayments
    }

    private var dailyLimit: Decimal {
        BudgetCalculator.dailyLimit(
            remainingBudget: periodRemainingBudget,
            daysRemaining: daysUntilSalary
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    portfolioCard

                    summaryCards

                    quickActions

                    upcomingPaymentsSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KALAN")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Ayarlar")
                }
            }
            .onAppear {
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "İşlem tamamlanamadı.")
            }
        }
    }

    private var portfolioCard: some View {
        Button {
            selectedTab = .assets
        } label: {
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text("Portföyüm")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.secondary)

                Text("Henüz hesaplanmadı")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("Varlıklarımın toplam TL karşılığı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            SummaryCard(
                title: "Aylık Gelirim",
                amount: monthlyIncome,
                icon: "arrow.down.left",
                color: .green,
                subtitle: "Maaş + ek gelir"
            )

            SummaryCard(
                title: "Aylık Harcamam",
                amount: monthlyPaid,
                icon: "arrow.up.right",
                color: .red,
                subtitle: "Ödenmiş ödemeler"
            )

            SummaryCard(
                title: "Kalan Bütçem",
                amount: remainingBudget,
                icon: "wallet.pass",
                color: .blue,
                subtitle: "Ödemeler düşüldü"
            )

            SummaryCard(
                title: "Günlük Limitim",
                amount: dailyLimit,
                icon: "calendar",
                color: .green,
                subtitle: "Tahmini · ay sonuna"
            )
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {

            Button {
                selectedAddType = 0
                selectedTab = .add
            } label: {
                Label("Gelir Ekle", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                selectedAddType = 1
                selectedTab = .add
            } label: {
                Label(
                    "Ödeme Ekle",
                    systemImage: "calendar.badge.plus"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Gecikmiş ve Yaklaşan Ödemeler")
                    .font(.headline)

                Spacer()

                Button("Tümünü Gör") {
                    selectedTab = .transactions
                }
                .font(.caption)
            }

            if upcomingPayments.isEmpty {

                ContentUnavailableView(
                    "Bekleyen ödemeniz yok",
                    systemImage: "checkmark.circle",
                    description: Text(
                        "Bu ay için bekleyen ödeme bulunmuyor."
                    )
                )

            } else {

                ForEach(upcomingPayments) { occurrence in

                    paymentRow(occurrence)

                    if occurrence.id != upcomingPayments.last?.id {
                        Divider()
                    }
                }
            }

            Divider()

            HStack {
                Text("Toplam Bekleyen")
                    .font(.subheadline)

                Spacer()

                Text(
                    formatCurrency(
                        upcomingPayments.reduce(.zero) {
                            $0 + $1.amount
                        }
                    )
                )
                .font(.subheadline.weight(.bold))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func paymentRow(
        _ occurrence: PaymentOccurrence
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {

                Text(occurrence.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(
                    occurrence.dueDate.formatted(
                        .dateTime.day().month(.wide)
                            .locale(trLocale)
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                // Ödeme tarihi geçmişse gecikmiş uyarısı göster
                if calendar.startOfDay(for: occurrence.dueDate)
                    < calendar.startOfDay(for: Date()) && !occurrence.isPaid {

                    Text("Gecikmiş")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                }

                Text(formatCurrency(occurrence.amount))
                    .font(.caption.weight(.semibold))
            }

            Spacer(minLength: 4)

            Button {
                selectedOccurrence = occurrence
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .accessibilityLabel("Ödemeyi düzenle")

            Button {
                togglePayment(occurrence)
            } label: {
                Text("Ödendi")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }

    private func generatePayments() {
        do {
            let today = Date()

            guard
                let startMonth = calendar.dateInterval(
                    of: .month,
                    for: salaryPeriodStart
                )?.start,
                let lastMonth = calendar.dateInterval(
                    of: .month,
                    for: calendar.date(
                        byAdding: .day,
                        value: 30,
                        to: today
                    ) ?? today
                )?.start
            else {
                return
            }

            var month = startMonth

            while month <= lastMonth {

                try PaymentOccurrenceService.generateOccurrences(
                    for: month,
                    context: modelContext
                )

                guard let next = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: month
                ) else {
                    break
                }

                month = next
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func togglePayment(
        _ occurrence: PaymentOccurrence
    ) {
        occurrence.isPaid = true
        occurrence.paidDate = Date()

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func formatCurrency(
        _ amount: Decimal
    ) -> String {
        amount.formatted(
            .currency(code: "TRY")
                .locale(trLocale)
        )
    }
}
