//
//  AnalyticsView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {

    @Query private var incomes: [Income]
    @Query private var payments: [Payment]
    @Query private var occurrences: [PaymentOccurrence]
    @Query private var incomeChanges: [IncomeAmountChange]
    @Query private var incomeOverrides: [IncomeOccurrenceOverride]

    @State private var selectedMonth = Date()

    private let calendar = Calendar.current
    private let trLocale = Locale(identifier: "tr_TR")

    private var summary: AnalyticsMonthSummary {
        AnalyticsCalculator.summary(
            for: selectedMonth,
            incomes: incomes,
            payments: payments,
            occurrences: occurrences,
            changes: incomeChanges,
            overrides: incomeOverrides
        )
    }

    private var history: [AnalyticsMonthSummary] {
        AnalyticsCalculator.lastSixMonths(
            from: selectedMonth,
            incomes: incomes,
            payments: payments,
            occurrences: occurrences,
            changes: incomeChanges,
            overrides: incomeOverrides
        )
    }

    private var categoryData: [CategoryChartItem] {
        summary.categories
            .map {
                CategoryChartItem(
                    name: $0.key,
                    amount: $0.value
                )
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    monthSelector

                    summarySection

                    incomePaymentChart

                    categoryChart
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analizler")
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
    }

    private var summarySection: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {

            SummaryCard(
                title: "Toplam Gelir",
                amount: summary.income,
                icon: "arrow.down.left",
                color: .green,
                subtitle: "Bu ayın gelirleri"
            )

            SummaryCard(
                title: "Planlanan Ödeme",
                amount: summary.plannedPayments,
                icon: "calendar",
                color: .orange,
                subtitle: "Ödenmiş + ödenmemiş"
            )

            SummaryCard(
                title: "Ödenen Tutar",
                amount: summary.paidPayments,
                icon: "checkmark.circle",
                color: .red,
                subtitle: "Tamamlanan ödemeler"
            )

            SummaryCard(
                title: "Kalan Bütçe",
                amount: summary.remainingBudget,
                icon: "wallet.pass",
                color: .blue,
                subtitle: "Gelir - planlanan ödeme"
            )
        }
    }

    private var incomePaymentChart: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Son 6 Ay")
                .font(.headline)

            Text("Gelir ve planlanan ödemeler")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(history.indices, id: \.self) { index in

                    let item = history[index]
                    let month = item.month.formatted(
                        .dateTime.month(.abbreviated)
                            .locale(trLocale)
                    )

                    BarMark(
                        x: .value("Ay", month),
                        y: .value(
                            "Gelir",
                            decimalToDouble(item.income)
                        )
                    )
                    .foregroundStyle(by: .value("Tür", "Gelir"))
                    .position(by: .value("Tür", "Gelir"))

                    BarMark(
                        x: .value("Ay", month),
                        y: .value(
                            "Ödeme",
                            decimalToDouble(item.plannedPayments)
                        )
                    )
                    .foregroundStyle(by: .value("Tür", "Ödeme"))
                    .position(by: .value("Tür", "Ödeme"))
                }
            }
            .chartForegroundStyleScale([
                "Gelir": Color.green,
                "Ödeme": Color.orange
            ])
            .chartYScale(domain: .automatic(includesZero: true))
            .frame(height: 240)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var categoryChart: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Ödeme Kategorileri")
                .font(.headline)

            Text("Bu ay ödenmiş tutarların dağılımı")
                .font(.caption)
                .foregroundStyle(.secondary)

            if categoryData.isEmpty {

                ContentUnavailableView(
                    "Henüz Veri Yok",
                    systemImage: "chart.pie",
                    description: Text(
                        "Bu ay ödenmiş ödeme bulunmuyor."
                    )
                )

            } else {

                Chart(categoryData) { category in
                    SectorMark(
                        angle: .value(
                            "Tutar",
                            decimalToDouble(category.amount)
                        ),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(
                        by: .value("Kategori", category.name)
                    )
                }
                .frame(height: 240)

                ForEach(categoryData) { category in
                    HStack {
                        Text(category.name)
                            .font(.subheadline)

                        Spacer()

                        Text(formatCurrency(category.amount))
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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

    private func decimalToDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: "TRY")
                .locale(trLocale)
        )
    }
}

private struct CategoryChartItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Decimal
}
