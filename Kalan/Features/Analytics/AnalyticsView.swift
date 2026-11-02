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
                    
                    categoryChart

                    incomePaymentChart
                }
                .padding(16)
            }
            .background {
                ZStack {
                    AnalyticsColors.background

                    RadialGradient(
                        colors: [
                            Color(red: 0.86, green: 0.96, blue: 0.91),
                            AnalyticsColors.background.opacity(0)
                        ],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 400
                    )
                }
                .ignoresSafeArea()
            }
            .tint(AnalyticsColors.primaryGreen)
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
            .font(.custom("AvenirNext-DemiBold", size: 18))

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
                .font(.custom("AvenirNext-DemiBold", size: 19))

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
                "Gelir": AnalyticsColors.primaryGreen,
                "Ödeme": AnalyticsColors.accentGreen
            ])
            .chartYScale(domain: .automatic(includesZero: true))
            .frame(height: 240)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .shadow(
            color: AnalyticsColors.primaryGreen.opacity(0.05),
            radius: 10,
            x: 0,
            y: 4
        )
    }

    private var categoryChart: some View {

        let total = categoryData.reduce(Decimal.zero) {
            $0 + $1.amount
        }

        return VStack(alignment: .leading, spacing: 18) {

            Text("Ödeme Kategorileri")
                .font(.custom("AvenirNext-DemiBold", size: 19))
                .foregroundStyle(.primary)

            Text("Seçilen ayın ödenmiş ödemeleri")
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(.secondary)

            if categoryData.isEmpty {

                ContentUnavailableView(
                    "Henüz Veri Yok",
                    systemImage: "chart.pie",
                    description: Text(
                        "Bu ay ödenmiş ödeme bulunmuyor."
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

            } else {

                ZStack {

                    Chart {
                        ForEach(categoryData.indices, id: \.self) { index in

                            let category = categoryData[index]

                            SectorMark(
                                angle: .value(
                                    "Tutar",
                                    decimalToDouble(category.amount)
                                ),
                                innerRadius: .ratio(0.72),
                                angularInset: 2
                            )
                            .foregroundStyle(categoryColor(at: index))
                            .cornerRadius(4)
                        }
                    }
                    .chartLegend(.hidden)
                    .frame(height: 250)

                    VStack(spacing: 5) {

                        Text(formatCurrency(total))
                            .font(.custom("AvenirNext-Bold", size: 22))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)

                        Text("Aylık Harcama")
                            .font(.custom("AvenirNext-Medium", size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: 175)
                    .allowsHitTesting(false)
                }

                VStack(spacing: 0) {

                    ForEach(categoryData.indices, id: \.self) { index in

                        let category = categoryData[index]

                        HStack(spacing: 10) {

                            Circle()
                                .fill(categoryColor(at: index))
                                .frame(width: 12, height: 12)

                            Text(category.name)
                                .font(.custom("AvenirNext-Medium", size: 14))
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Spacer(minLength: 8)

                            Text(
                                categoryPercentage(
                                    amount: category.amount,
                                    total: total
                                )
                            )
                            .font(.custom("AvenirNext-Medium", size: 13))
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)

                            Text(formatCurrency(category.amount))
                                .font(.custom("AvenirNext-DemiBold", size: 13))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .frame(
                                    minWidth: 100,
                                    alignment: .trailing
                                )
                        }
                        .padding(.vertical, 13)

                        if index < categoryData.count - 1 {
                            Divider()
                                .overlay(
                                    AnalyticsColors.background
                                )
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .shadow(
            color: AnalyticsColors.primaryGreen.opacity(0.05),
            radius: 10,
            x: 0,
            y: 4
        )
    }
    
    private func categoryColor(at index: Int) -> Color {
        let palette = AnalyticsColors.categoryPalette
        return palette[index % palette.count]
    }

    private func categoryPercentage(
        amount: Decimal,
        total: Decimal
    ) -> String {

        guard total > .zero else {
            return "%0"
        }

        let percentage = (
            decimalToDouble(amount) / decimalToDouble(total)
        ) * 100

        return String(format: "%%%0.1f", percentage)
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
