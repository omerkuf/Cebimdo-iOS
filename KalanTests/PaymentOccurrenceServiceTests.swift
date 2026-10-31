//
//  PaymentOccurrenceServiceTests.swift
//  KalanTests
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import XCTest
@testable import Kalan

final class PaymentOccurrenceServiceTests: XCTestCase {

    private let calendar = Calendar.current

    private func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: 12
            )
        )!
    }

    // Her ayın 15'inde tekrar eden ödeme
    func testMonthlyPaymentDate() {
        let startDate = makeDate(2026, 10, 15)

        let dates = RecurrenceService.dates(
            in: makeDate(2026, 12, 1),
            from: startDate,
            recurrence: .monthly,
            endDate: nil
        )

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(
            calendar.component(.day, from: dates[0]),
            15
        )
    }

    // 31'inde başlayan ödeme Şubat'ın son gününe denk gelmeli
    func testMonthlyPaymentOnLastDayOfFebruary() {
        let startDate = makeDate(2026, 10, 31)

        let dates = RecurrenceService.dates(
            in: makeDate(2027, 2, 1),
            from: startDate,
            recurrence: .monthly,
            endDate: nil
        )

        XCTAssertEqual(dates.count, 1)
        XCTAssertEqual(
            calendar.component(.day, from: dates[0]),
            28
        )
    }

    // Tek seferlik ödeme sonraki ayda tekrar oluşmamalı
    func testOneTimePaymentDoesNotRepeat() {
        let startDate = makeDate(2026, 10, 15)

        let dates = RecurrenceService.dates(
            in: makeDate(2026, 11, 1),
            from: startDate,
            recurrence: .once,
            endDate: nil
        )

        XCTAssertTrue(dates.isEmpty)
    }
}

