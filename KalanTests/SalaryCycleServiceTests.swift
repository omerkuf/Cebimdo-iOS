//
//  SalaryCycleServiceTests.swift
//  KalanTests
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//


import XCTest
@testable import Kalan

final class SalaryCycleServiceTests: XCTestCase {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        )!
    }

    func testSalaryDay31InFebruary() throws {

        let cycle = try XCTUnwrap(
            SalaryCycleService.cycle(
                salaryDay: 31,
                from: date(2027, 2, 15),
                calendar: calendar
            )
        )

        XCTAssertEqual(
            cycle.startDate,
            date(2027, 1, 31)
        )

        XCTAssertEqual(
            cycle.endDate,
            date(2027, 2, 28)
        )

        XCTAssertEqual(cycle.daysRemaining, 13)
    }

    func testSalaryDayStartsNewCycle() throws {

        let cycle = try XCTUnwrap(
            SalaryCycleService.cycle(
                salaryDay: 31,
                from: date(2027, 2, 28),
                calendar: calendar
            )
        )

        XCTAssertEqual(
            cycle.startDate,
            date(2027, 2, 28)
        )

        XCTAssertEqual(
            cycle.endDate,
            date(2027, 3, 31)
        )

        XCTAssertEqual(cycle.daysRemaining, 31)
    }

    func testYearTransition() throws {

        let cycle = try XCTUnwrap(
            SalaryCycleService.cycle(
                salaryDay: 15,
                from: date(2026, 12, 20),
                calendar: calendar
            )
        )

        XCTAssertEqual(
            cycle.startDate,
            date(2026, 12, 15)
        )

        XCTAssertEqual(
            cycle.endDate,
            date(2027, 1, 15)
        )

        XCTAssertEqual(cycle.daysRemaining, 26)
    }

    func testInvalidSalaryDay() {
        XCTAssertNil(
            SalaryCycleService.cycle(
                salaryDay: 32,
                calendar: calendar
            )
        )
    }
}

