//
//  AnalyticsCalculator.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct AnalyticsPaymentItem {
    let category: String
    let amount: Decimal
    let isPaid: Bool
}

struct AnalyticsMonthSummary {
    let month: Date
    let income: Decimal
    let plannedPayments: Decimal
    let paidPayments: Decimal
    let categories: [String: Decimal]

    var remainingBudget: Decimal {
        income - plannedPayments
    }
}

struct AnalyticsCalculator {

    static func summary(
        for month: Date,
        incomes: [Income],
        payments: [Payment],
        occurrences: [PaymentOccurrence],
        calendar: Calendar = .current
    ) -> AnalyticsMonthSummary {

        let incomeTotal = incomes.reduce(Decimal.zero) {
            total, income in

            let dates = RecurrenceService.dates(
                in: month,
                from: income.startDate,
                recurrence: RecurrenceType(
                    rawValue: income.recurrence
                ) ?? .once,
                endDate: income.endDate,
                calendar: calendar
            )

            return total
                + income.amount * Decimal(dates.count)
        }

        let paymentItems = payments.flatMap { payment in

            let dates = RecurrenceService.dates(
                in: month,
                from: payment.startDate,
                recurrence: RecurrenceType(
                    rawValue: payment.recurrence
                ) ?? .once,
                endDate: payment.endDate,
                calendar: calendar
            )

            return dates.map { date in

                let savedOccurrence = occurrences.first {
                    $0.paymentID == payment.id &&
                    calendar.isDate(
                        $0.scheduledDate ?? $0.dueDate,
                        inSameDayAs: date
                    )
                }

                return AnalyticsPaymentItem(
                    category: payment.category,
                    amount: savedOccurrence?.amount
                        ?? payment.amount,
                    isPaid: savedOccurrence?.isPaid
                        ?? false
                )
            }
        }

        let plannedTotal = paymentItems.reduce(Decimal.zero) {
            $0 + $1.amount
        }

        let paidItems = paymentItems.filter { $0.isPaid }

        let paidTotal = paidItems.reduce(Decimal.zero) {
            $0 + $1.amount
        }

        let categories = Dictionary(
            grouping: paidItems,
            by: \.category
        )
        .mapValues { items in
            items.reduce(Decimal.zero) {
                $0 + $1.amount
            }
        }

        return AnalyticsMonthSummary(
            month: month,
            income: incomeTotal,
            plannedPayments: plannedTotal,
            paidPayments: paidTotal,
            categories: categories
        )
    }

    static func lastSixMonths(
        from date: Date,
        incomes: [Income],
        payments: [Payment],
        occurrences: [PaymentOccurrence],
        calendar: Calendar = .current
    ) -> [AnalyticsMonthSummary] {

        (-5...0).compactMap { offset in

            guard let month = calendar.date(
                byAdding: .month,
                value: offset,
                to: date
            ) else {
                return nil
            }

            return summary(
                for: month,
                incomes: incomes,
                payments: payments,
                occurrences: occurrences,
                calendar: calendar
            )
        }
    }
}
