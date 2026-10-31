//
//  IncomeHistoryServiceTests.swift
//  KalanTests
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import XCTest
@testable import Kalan

final class IncomeHistoryServiceTests: XCTestCase {

    private var calendar: Calendar {
        Calendar(identifier: .gregorian)
    }

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

    private func makeIncome() -> Income {
        Income(
            name: "Maaş",
            amount: 30_000,
            category: "Maaş",
            startDate: makeDate(2026, 10, 1),
            recurrence: .monthly,
            note: ""
        )
    }

    // Değişiklik yoksa bütün dönemler başlangıç tutarını kullanır.
    func testIncomeWithoutChanges() {
        let income = makeIncome()

        let octoberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 10, 1),
            changes: []
        )

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: []
        )

        XCTAssertEqual(octoberAmount, 30_000)
        XCTAssertEqual(decemberAmount, 30_000)
    }

    // Aralık değişikliği Ekim ve Kasım aylarını etkilememeli.
    func testFutureIncomeChangeDoesNotAffectPast() {
        let income = makeIncome()

        let decemberChange = IncomeAmountChange(
            incomeID: income.id,
            effectiveDate: makeDate(2026, 12, 1),
            amount: 40_000
        )

        let octoberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 10, 1),
            changes: [decemberChange]
        )

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: [decemberChange]
        )

        let januaryAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2027, 1, 1),
            changes: [decemberChange]
        )

        XCTAssertEqual(octoberAmount, 30_000)
        XCTAssertEqual(decemberAmount, 40_000)
        XCTAssertEqual(januaryAmount, 40_000)
    }

    // Birden fazla değişiklik varsa ilgili tarihteki son
    // geçerli değişikliğin tutarı kullanılmalı.
    func testLatestApplicableIncomeChange() {
        let income = makeIncome()

        let novemberChange = IncomeAmountChange(
            incomeID: income.id,
            effectiveDate: makeDate(2026, 11, 1),
            amount: 35_000
        )

        let januaryChange = IncomeAmountChange(
            incomeID: income.id,
            effectiveDate: makeDate(2027, 1, 1),
            amount: 45_000
        )

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: [januaryChange, novemberChange]
        )

        let februaryAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2027, 2, 1),
            changes: [januaryChange, novemberChange]
        )

        XCTAssertEqual(decemberAmount, 35_000)
        XCTAssertEqual(februaryAmount, 45_000)
    }
    
    // Tek dönemlik değişiklik diğer ayları etkilememeli.
    func testOnlySelectedIncomeOccurrenceChanges() {
        let income = makeIncome()

        let novemberOverride = IncomeOccurrenceOverride(
            incomeID: income.id,
            occurrenceDate: makeDate(2026, 11, 1),
            amount: 50_000
        )

        let octoberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 10, 1),
            changes: [],
            overrides: [novemberOverride]
        )

        let novemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 11, 1),
            changes: [],
            overrides: [novemberOverride]
        )

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: [],
            overrides: [novemberOverride]
        )

        XCTAssertEqual(octoberAmount, 30_000)
        XCTAssertEqual(novemberAmount, 50_000)
        XCTAssertEqual(decemberAmount, 30_000)
    }
    
    // Tek dönemlik özel tutar, ileriye dönük tutarı ezmeli.
    func testOccurrenceOverrideTakesPriority() {
        let income = makeIncome()

        let futureChange = IncomeAmountChange(
            incomeID: income.id,
            effectiveDate: makeDate(2026, 11, 1),
            amount: 40_000
        )

        let decemberOverride = IncomeOccurrenceOverride(
            incomeID: income.id,
            occurrenceDate: makeDate(2026, 12, 1),
            amount: 55_000
        )

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: [futureChange],
            overrides: [decemberOverride]
        )

        let januaryAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2027, 1, 1),
            changes: [futureChange],
            overrides: [decemberOverride]
        )

        XCTAssertEqual(decemberAmount, 55_000)
        XCTAssertEqual(januaryAmount, 40_000)
    }
    
    
    // Aylık maaş ve tek seferlik prim aynı ayda toplanmalı.
    func testMonthlyTotalWithOneTimeBonus() {
        let salary = makeIncome()

        let bonus = Income(
            name: "Prim",
            amount: 10_000,
            category: "Prim / İkramiye",
            startDate: makeDate(2026, 11, 15),
            recurrence: .once,
            note: ""
        )

        let octoberTotal = IncomeHistoryService.monthlyTotal(
            incomes: [salary, bonus],
            changes: [],
            month: makeDate(2026, 10, 1)
        )

        let novemberTotal = IncomeHistoryService.monthlyTotal(
            incomes: [salary, bonus],
            changes: [],
            month: makeDate(2026, 11, 1)
        )

        let decemberTotal = IncomeHistoryService.monthlyTotal(
            incomes: [salary, bonus],
            changes: [],
            month: makeDate(2026, 12, 1)
        )

        XCTAssertEqual(octoberTotal, 30_000)
        XCTAssertEqual(novemberTotal, 40_000)
        XCTAssertEqual(decemberTotal, 30_000)
    }
}

