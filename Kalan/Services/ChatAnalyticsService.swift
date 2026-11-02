//
//  ChatAnalyticsService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//


import Foundation

struct ChatAnalyticsService {

    static func answer(
        intent: ChatIntentResult,
        incomes: [Income],
        payments: [Payment],
        occurrences: [PaymentOccurrence],
        changes: [IncomeAmountChange],
        overrides: [IncomeOccurrenceOverride]
    ) -> String {

        let calendar = Calendar.current
        let locale = Locale(identifier: "tr_TR")

        let parts = intent.month.split(separator: "-")

        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1...12).contains(month),
              let date = calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: 1
                )
              ) else {
            return "Hangi ayı sorduğunu anlayamadım. Örneğin Kasım 2026 diyebilirsin."
        }

        let summary = AnalyticsCalculator.summary(
            for: date,
            incomes: incomes,
            payments: payments,
            occurrences: occurrences,
            changes: changes,
            overrides: overrides
        )

        let monthName = date.formatted(
            .dateTime.month(.wide).year().locale(locale)
        )

        func currency(_ value: Decimal) -> String {
            value.formatted(
                .currency(code: "TRY").locale(locale)
            )
        }

        switch intent.intent {

        case .monthlyIncome:
            return "\(monthName) toplam gelirin \(currency(summary.income))."

        case .paidPayments:
            return "\(monthName) döneminde toplam \(currency(summary.paidPayments)) ödeme yapmışsın."

        case .plannedPayments:
            return "\(monthName) dönemindeki toplam planlanan ödemen \(currency(summary.plannedPayments)). Bu tutara ödenmiş ve ödenmemiş kayıtlar dahil."

        case .remainingBudget:
            return "\(monthName) için kalan bütçen \(currency(summary.remainingBudget)). Bu değer gelirinden planlanan ödemeler çıkarılarak hesaplandı."

        case .topCategory:
            guard let category = summary.categories.max(
                by: { $0.value < $1.value }
            ), category.value > .zero else {
                return "\(monthName) için ödenmiş ödeme kategorisi bulunmuyor."
            }

            return "\(monthName) döneminde en yüksek ödenmiş ödeme kategorin \(category.key). Bu kategoride toplam \(currency(category.value)) ödeme yapmışsın."

        case .comparePreviousMonth:
            guard let previousDate = calendar.date(
                byAdding: .month,
                value: -1,
                to: date
            ) else {
                return "Önceki ayın verileri hesaplanamadı."
            }

            let previous = AnalyticsCalculator.summary(
                for: previousDate,
                incomes: incomes,
                payments: payments,
                occurrences: occurrences,
                changes: changes,
                overrides: overrides
            )

            let difference = summary.paidPayments - previous.paidPayments

            if difference == .zero {
                return "\(monthName) döneminde geçen ayla aynı tutarda, \(currency(summary.paidPayments)) ödeme yapmışsın."
            }

            if difference > .zero {
                return "\(monthName) döneminde önceki aya göre \(currency(difference)) daha fazla ödeme yapmışsın. Bu ay toplam ödemen \(currency(summary.paidPayments))."
            }

            return "\(monthName) döneminde önceki aya göre \(currency(-difference)) daha az ödeme yapmışsın. Bu ay toplam ödemen \(currency(summary.paidPayments))."

        case .portfolioTotal,
             .assetValue,
             .assetQuantity,
             .assetList:

            return "Varlık bilgileri ChatAssetService üzerinden hesaplanıyor."

        case .unsupported:

            return "Gelirlerini, ödemelerini, bütçeni ve varlıklarını inceleyebiliyorum."
        }
    }
}

