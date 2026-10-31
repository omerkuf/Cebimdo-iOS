//
//  IncomeSeriesEditServiceTests.swift
//  KalanTests
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import XCTest
import SwiftData
@testable import Kalan

@MainActor
final class IncomeSeriesEditServiceTests: XCTestCase {

    private func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        Calendar.current.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: 12
            )
        )!
    }

    private var testContainer: ModelContainer!

    private func makeContext() throws -> ModelContext {

        let schema = Schema([
            Income.self,
            IncomeAmountChange.self,
            IncomeOccurrenceOverride.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        testContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        return testContainer.mainContext
    }
    
    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }

    // Eski ileri tarihli değişiklikler silinmeli.
    func testEarlierEditOverwritesFutureChanges() throws {
        let context = try makeContext()

        let income = Income(
            name: "Maaş",
            amount: 30_000,
            category: "Maaş",
            startDate: makeDate(2026, 10, 1),
            recurrence: .monthly,
            note: ""
        )

        context.insert(income)

        let decemberChange = IncomeAmountChange(
            incomeID: income.id,
            effectiveDate: makeDate(2026, 12, 1),
            amount: 40_000
        )

        context.insert(decemberChange)
        try context.save()

        IncomeSeriesEditService.updateThisAndFuture(
            income: income,
            effectiveDate: makeDate(2026, 10, 1),
            amount: 50_000,
            changes: [decemberChange],
            overrides: [],
            context: context
        )

        try context.save()

        let savedChanges = try context.fetch(
            FetchDescriptor<IncomeAmountChange>()
        ).filter { $0.incomeID == income.id }

        // Aralık'taki eski değişiklik silinmiş olmalı.
        XCTAssertEqual(savedChanges.count, 1)

        let octoberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 10, 1),
            changes: savedChanges
        )

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: savedChanges
        )

        let januaryAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2027, 1, 1),
            changes: savedChanges
        )

        XCTAssertEqual(octoberAmount, 50_000)
        XCTAssertEqual(decemberAmount, 50_000)
        XCTAssertEqual(januaryAmount, 50_000)
    }

    // Gelecek dönemlerdeki tek seferlik özel tutarlar da silinmeli.
    func testEarlierEditRemovesFutureOverrides() throws {
        let context = try makeContext()

        let income = Income(
            name: "Maaş",
            amount: 30_000,
            category: "Maaş",
            startDate: makeDate(2026, 10, 1),
            recurrence: .monthly,
            note: ""
        )

        context.insert(income)

        let decemberOverride = IncomeOccurrenceOverride(
            incomeID: income.id,
            occurrenceDate: makeDate(2026, 12, 1),
            amount: 60_000
        )

        context.insert(decemberOverride)
        try context.save()

        IncomeSeriesEditService.updateThisAndFuture(
            income: income,
            effectiveDate: makeDate(2026, 10, 1),
            amount: 50_000,
            changes: [],
            overrides: [decemberOverride],
            context: context
        )

        try context.save()

        let savedChanges = try context.fetch(
            FetchDescriptor<IncomeAmountChange>()
        ).filter { $0.incomeID == income.id }

        let savedOverrides = try context.fetch(
            FetchDescriptor<IncomeOccurrenceOverride>()
        ).filter { $0.incomeID == income.id }

        XCTAssertTrue(savedOverrides.isEmpty)

        let decemberAmount = IncomeHistoryService.amount(
            for: income,
            on: makeDate(2026, 12, 1),
            changes: savedChanges,
            overrides: savedOverrides
        )

        XCTAssertEqual(decemberAmount, 50_000)
    }
}

