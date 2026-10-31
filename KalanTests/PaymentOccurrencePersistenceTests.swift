//
//  PaymentOccurrencePersistenceTests.swift
//  KalanTests
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import XCTest
import SwiftData
@testable import Kalan

@MainActor
final class PaymentOccurrencePersistenceTests: XCTestCase {

    private var testContainer: ModelContainer!

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

    private func makeContext() throws -> ModelContext {

        let schema = Schema([
            Payment.self,
            PaymentOccurrence.self
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

    private func makePayment() -> Payment {
        Payment(
            name: "Kira",
            amount: 5_000,
            category: "Kira",
            startDate: makeDate(2026, 10, 15),
            recurrence: .monthly,
            note: ""
        )
    }

    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }

    // Aynı ay için servis iki kere çağrıldığında
    // ikinci bir ödeme kaydı oluşmamalı.
    func testGeneratingSameMonthTwiceDoesNotDuplicate() throws {

        let context = try makeContext()
        let payment = makePayment()

        context.insert(payment)
        try context.save()

        let november = makeDate(2026, 11, 1)

        try PaymentOccurrenceService.generateOccurrences(
            for: november,
            context: context
        )

        try PaymentOccurrenceService.generateOccurrences(
            for: november,
            context: context
        )

        let savedOccurrences = try context.fetch(
            FetchDescriptor<PaymentOccurrence>()
        )

        let novemberOccurrences = savedOccurrences.filter {
            $0.paymentID == payment.id &&
            Calendar.current.isDate(
                $0.dueDate,
                equalTo: november,
                toGranularity: .month
            )
        }

        XCTAssertEqual(novemberOccurrences.count, 1)
    }

    // Ödenmiş kayıt yeniden üretim sırasında
    // ödenmemiş hale dönmemeli.
    func testPaidOccurrenceRemainsPaidAfterRegeneration() throws {

        let context = try makeContext()
        let payment = makePayment()

        context.insert(payment)
        try context.save()

        let october = makeDate(2026, 10, 1)

        try PaymentOccurrenceService.generateOccurrences(
            for: october,
            context: context
        )

        let firstFetch = try context.fetch(
            FetchDescriptor<PaymentOccurrence>()
        )

        let octoberOccurrence = try XCTUnwrap(
            firstFetch.first {
                $0.paymentID == payment.id &&
                Calendar.current.isDate(
                    $0.dueDate,
                    equalTo: october,
                    toGranularity: .month
                )
            }
        )

        octoberOccurrence.isPaid = true
        octoberOccurrence.paidDate = makeDate(2026, 10, 15)

        try context.save()

        // Aynı aya ait kayıtları yeniden oluşturmayı dene.
        try PaymentOccurrenceService.generateOccurrences(
            for: october,
            context: context
        )

        let savedOccurrences = try context.fetch(
            FetchDescriptor<PaymentOccurrence>()
        )

        let octoberOccurrences = savedOccurrences.filter {
            $0.paymentID == payment.id &&
            Calendar.current.isDate(
                $0.dueDate,
                equalTo: october,
                toGranularity: .month
            )
        }

        XCTAssertEqual(octoberOccurrences.count, 1)
        XCTAssertEqual(octoberOccurrences.first?.isPaid, true)
        XCTAssertNotNil(octoberOccurrences.first?.paidDate)
    }
}

