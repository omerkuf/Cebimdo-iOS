//
//  RecurrenceService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct RecurrenceService {

    static func occurrenceDates(
        from startDate: Date,
        recurrence: RecurrenceType,
        until endDate: Date,
        calendar: Calendar = .current
    ) -> [Date] {

        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        guard start <= end else { return [] }

        var dates: [Date] = []
        var current = start

        while current <= end {
            dates.append(current)

            switch recurrence {
            case .once:
                return dates

            case .weekly:
                guard let next = calendar.date(
                    byAdding: .weekOfYear,
                    value: 1,
                    to: current
                ) else { return dates }
                current = next

            case .monthly:
                let monthIndex = dates.count

                guard let next = calendar.date(
                    byAdding: .month,
                    value: monthIndex,
                    to: start
                ) else { return dates }

                current = next

            case .yearly:
                let yearIndex = dates.count

                guard let next = calendar.date(
                    byAdding: .year,
                    value: yearIndex,
                    to: start
                ) else { return dates }

                current = next
            }
        }

        return dates
    }

    static func dates(
        in month: Date,
        from startDate: Date,
        recurrence: RecurrenceType,
        endDate: Date? = nil,
        calendar: Calendar = .current
    ) -> [Date] {

        guard let interval = calendar.dateInterval(
            of: .month,
            for: month
        ) else {
            return []
        }

        let start = calendar.startOfDay(for: startDate)
        let effectiveEnd = endDate.map {
            calendar.startOfDay(for: $0)
        }

        guard effectiveEnd == nil || effectiveEnd! >= start else {
            return []
        }

        let dayCount = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: interval.end
        ).day ?? 0

        guard dayCount > 0 else { return [] }

        // İlgili aya kadarki günleri tarayarak
        // doğru tekrarlama tarihlerini buluyoruz.
        let firstDay = max(
            start,
            calendar.startOfDay(for: interval.start)
        )

        var result: [Date] = []
        var day = firstDay

        while day < interval.end {

            if let effectiveEnd, day > effectiveEnd {
                break
            }

            let components = calendar.dateComponents(
                [.year, .month, .day],
                from: day
            )

            let startComponents = calendar.dateComponents(
                [.year, .month, .day],
                from: start
            )

            let dayDifference = calendar.dateComponents(
                [.day],
                from: start,
                to: day
            ).day ?? -1

            let monthDifference =
                ((components.year ?? 0) - (startComponents.year ?? 0)) * 12
                + (components.month ?? 0)
                - (startComponents.month ?? 0)

            let daysInMonth = calendar.range(
                of: .day,
                in: .month,
                for: day
            )?.count ?? 31

            let expectedDay = min(
                startComponents.day ?? 1,
                daysInMonth
            )

            let matches: Bool

            switch recurrence {
            case .once:
                matches = calendar.isDate(day, inSameDayAs: start)

            case .weekly:
                matches = dayDifference >= 0
                    && dayDifference % 7 == 0

            case .monthly:
                matches = monthDifference >= 0
                    && components.day == expectedDay

            case .yearly:
                matches = monthDifference >= 0
                    && monthDifference % 12 == 0
                    && components.day == expectedDay
            }

            if matches {
                result.append(day)
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: day
            ) else {
                break
            }

            day = nextDay
        }

        return result
    }
}
