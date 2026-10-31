//
//  DashboardCalculator.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct DashboardCalculator {

    static func monthlyIncome(
        incomes: [Income],
        month: Date,
        changes: [IncomeAmountChange] = [],
        overrides: [IncomeOccurrenceOverride] = []
    ) -> Decimal {

        IncomeHistoryService.monthlyTotal(
            incomes: incomes,
            changes: changes,
            month: month,
            overrides: overrides
        )
    }

    static func monthlyPaid(
        occurrences: [PaymentOccurrence]
    ) -> Decimal {

        occurrences
            .filter { $0.isPaid }
            .reduce(.zero) { $0 + $1.amount }
    }

    static func monthlyUnpaid(
        occurrences: [PaymentOccurrence]
    ) -> Decimal {

        occurrences
            .filter { !$0.isPaid }
            .reduce(.zero) { $0 + $1.amount }
    }

    static func remainingBudget(
        income: Decimal,
        occurrences: [PaymentOccurrence]
    ) -> Decimal {

        let allPayments = occurrences.reduce(.zero) {
            $0 + $1.amount
        }

        return income - allPayments
    }

    static func dailyLimit(
        remainingBudget: Decimal,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Decimal {

        guard let interval = calendar.dateInterval(
            of: .month,
            for: date
        ) else {
            return .zero
        }

        let today = calendar.startOfDay(for: date)

        let daysRemaining = calendar.dateComponents(
            [.day],
            from: today,
            to: interval.end
        ).day ?? 1

        return max(.zero, remainingBudget)
            / Decimal(max(1, daysRemaining))
    }
}
