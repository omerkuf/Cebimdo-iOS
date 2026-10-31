//
//  SalaryCycleService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import Foundation

struct SalaryCycle {
    let startDate: Date
    let endDate: Date
    let daysRemaining: Int
}

struct SalaryCycleService {

    static func cycle(
        salaryDay: Int,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> SalaryCycle? {

        guard (1...31).contains(salaryDay) else {
            return nil
        }

        let today = calendar.startOfDay(for: date)

        guard let currentMonth = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: today
            )
        ) else {
            return nil
        }

        guard let thisSalaryDate = salaryDate(
            in: currentMonth,
            salaryDay: salaryDay,
            calendar: calendar
        ) else {
            return nil
        }

        let previousMonth = calendar.date(
            byAdding: .month,
            value: -1,
            to: currentMonth
        )

        let nextMonth = calendar.date(
            byAdding: .month,
            value: 1,
            to: currentMonth
        )

        let startDate: Date
        let endDate: Date

        if today >= thisSalaryDate {
            startDate = thisSalaryDate

            guard let nextMonth,
                  let nextDate = salaryDate(
                    in: nextMonth,
                    salaryDay: salaryDay,
                    calendar: calendar
                  ) else {
                return nil
            }

            endDate = nextDate
        } else {
            endDate = thisSalaryDate

            guard let previousMonth,
                  let previousDate = salaryDate(
                    in: previousMonth,
                    salaryDay: salaryDay,
                    calendar: calendar
                  ) else {
                return nil
            }

            startDate = previousDate
        }

        let daysRemaining = calendar.dateComponents(
            [.day],
            from: today,
            to: endDate
        ).day ?? 0

        return SalaryCycle(
            startDate: startDate,
            endDate: endDate,
            daysRemaining: max(daysRemaining, 1)
        )
    }

    private static func salaryDate(
        in month: Date,
        salaryDay: Int,
        calendar: Calendar
    ) -> Date? {

        guard let dayRange = calendar.range(
            of: .day,
            in: .month,
            for: month
        ) else {
            return nil
        }

        let validDay = min(
            salaryDay,
            dayRange.count
        )

        return calendar.date(
            byAdding: .day,
            value: validDay - 1,
            to: month
        )
    }
}

