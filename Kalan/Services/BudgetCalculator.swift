//
//  BudgetCalculator.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct BudgetCalculator {

    static func nextSalaryDate(
        salaryDay: Int,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {

        let today = calendar.startOfDay(for: date)
        let day = min(max(salaryDay, 1), 31)

        func salaryDate(for month: Date) -> Date? {
            guard let interval = calendar.dateInterval(
                of: .month,
                for: month
            ), let range = calendar.range(
                of: .day,
                in: .month,
                for: month
            ) else {
                return nil
            }

            return calendar.date(
                byAdding: .day,
                value: min(day, range.count) - 1,
                to: interval.start
            )
        }

        if let current = salaryDate(for: today),
           current > today {
            return current
        }

        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: today
        ) else {
            return today
        }

        return salaryDate(for: nextMonth) ?? today
    }

    static func previousSalaryDate(
        salaryDay: Int,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {

        let today = calendar.startOfDay(for: date)
        let day = min(max(salaryDay, 1), 31)

        func salaryDate(for month: Date) -> Date? {
            guard let interval = calendar.dateInterval(
                of: .month,
                for: month
            ), let range = calendar.range(
                of: .day,
                in: .month,
                for: month
            ) else {
                return nil
            }

            return calendar.date(
                byAdding: .day,
                value: min(day, range.count) - 1,
                to: interval.start
            )
        }

        if let current = salaryDate(for: today),
           current <= today {
            return current
        }

        guard let previousMonth = calendar.date(
            byAdding: .month,
            value: -1,
            to: today
        ) else {
            return today
        }

        return salaryDate(for: previousMonth) ?? today
    }

    static func daysUntilSalary(
        salaryDay: Int,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {

        let nextDate = nextSalaryDate(
            salaryDay: salaryDay,
            from: date,
            calendar: calendar
        )

        return max(
            1,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: date),
                to: nextDate
            ).day ?? 1
        )
    }

    static func dailyLimit(
        remainingBudget: Decimal,
        daysRemaining: Int
    ) -> Decimal {

        max(.zero, remainingBudget)
            / Decimal(max(1, daysRemaining))
    }
}
