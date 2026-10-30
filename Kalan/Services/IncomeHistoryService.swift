//
//  IncomeHistoryService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct IncomeHistoryService {

    static func amount(
        for income: Income,
        on date: Date,
        changes: [IncomeAmountChange]
    ) -> Decimal {

        let calendar = Calendar.current
        let occurrenceDay = calendar.startOfDay(for: date)

        let applicableChange = changes
            .filter {
                $0.incomeID == income.id &&
                calendar.startOfDay(for: $0.effectiveDate) <= occurrenceDay
            }
            .sorted {
                if $0.effectiveDate == $1.effectiveDate {
                    return $0.createdAt > $1.createdAt
                }

                return $0.effectiveDate > $1.effectiveDate
            }
            .first

        return applicableChange?.amount ?? income.amount
    }

    static func monthlyTotal(
        incomes: [Income],
        changes: [IncomeAmountChange],
        month: Date
    ) -> Decimal {

        incomes.reduce(Decimal.zero) { total, income in

            let dates = RecurrenceService.dates(
                in: month,
                from: income.startDate,
                recurrence: RecurrenceType(
                    rawValue: income.recurrence
                ) ?? .once,
                endDate: income.endDate
            )

            let incomeTotal = dates.reduce(Decimal.zero) {
                subtotal, date in

                subtotal + amount(
                    for: income,
                    on: date,
                    changes: changes
                )
            }

            return total + incomeTotal
        }
    }
}
