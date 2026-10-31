//
//  PaymentSeriesEditServiceTests.swift
//  KalanTests
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import XCTest
import SwiftData
@testable import Kalan

@MainActor
final class PaymentSeriesEditServiceTests: XCTestCase {

    private var testContainer: ModelContainer!
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

    private func occurrences(
        in context: ModelContext
    ) throws -> [PaymentOccurrence] {
        try context.fetch(
            FetchDescriptor<PaymentOccurrence>()
        )
    }

    private func occurrence(
        in month: Int,
        year: Int = 2026,
        context: ModelContext
    ) throws -> PaymentOccurrence {

        let matches = try occurrences(in: context).filter {
            calendar.component(.year, from: $0.dueDate) == year &&
            calendar.component(.month, from: $0.dueDate) == month
        }

        XCTAssertEqual(matches.count, 1)

        return try XCTUnwrap(matches.first)
    }

    // Ekim ödenmişken Kasım'dan itibaren tarihi değiştir.
    func testChangingFutureDatesPreservesPaidHistory() throws {

        let context = try makeContext()
        let payment = makePayment()

        context.insert(payment)
        try context.save()

        for month in 10...12 {
            try PaymentOccurrenceService.generateOccurrences(
                for: makeDate(2026, month, 1),
                context: context
            )
        }

        let october = try occurrence(
            in: 10,
            context: context
        )

        october.isPaid = true
        october.paidDate = makeDate(2026, 10, 15)
        try context.save()

        let november = try occurrence(
            in: 11,
            context: context
        )

        try PaymentSeriesEditService.changeFutureDates(
            occurrence: november,
            newDate: makeDate(2026, 11, 20),
            context: context
        )

        let savedOctober = try occurrence(
            in: 10,
            context: context
        )

        let savedNovember = try occurrence(
            in: 11,
            context: context
        )

        let savedDecember = try occurrence(
            in: 12,
            context: context
        )

        XCTAssertEqual(
            calendar.component(.day, from: savedOctober.dueDate),
            15
        )
        XCTAssertTrue(savedOctober.isPaid)
        XCTAssertNotNil(savedOctober.paidDate)
        XCTAssertEqual(savedOctober.paymentID, payment.id)

        XCTAssertEqual(
            calendar.component(.day, from: savedNovember.dueDate),
            20
        )
        XCTAssertEqual(
            calendar.component(.day, from: savedDecember.dueDate),
            20
        )

        XCTAssertFalse(savedNovember.isPaid)
        XCTAssertFalse(savedDecember.isPaid)

        XCTAssertNotEqual(savedNovember.paymentID, payment.id)
        XCTAssertEqual(
            savedNovember.paymentID,
            savedDecember.paymentID
        )
    }

    // Tarih değiştikten sonra ayları tekrar oluşturmak
    // aynı ödeme için ikinci kayıt üretmemeli.
    func testReschedulingDoesNotCreateDuplicates() throws {

        let context = try makeContext()
        let payment = makePayment()

        context.insert(payment)
        try context.save()

        for month in 10...12 {
            try PaymentOccurrenceService.generateOccurrences(
                for: makeDate(2026, month, 1),
                context: context
            )
        }

        let november = try occurrence(
            in: 11,
            context: context
        )

        try PaymentSeriesEditService.changeFutureDates(
            occurrence: november,
            newDate: makeDate(2026, 11, 20),
            context: context
        )

        for month in 10...12 {
            try PaymentOccurrenceService.generateOccurrences(
                for: makeDate(2026, month, 1),
                context: context
            )
        }

        let all = try occurrences(in: context)

        XCTAssertEqual(all.count, 3)

        for month in 10...12 {
            let matches = all.filter {
                calendar.component(.year, from: $0.dueDate) == 2026 &&
                calendar.component(.month, from: $0.dueDate) == month
            }

            XCTAssertEqual(matches.count, 1)
        }

        let savedNovember = try occurrence(
            in: 11,
            context: context
        )

        let savedDecember = try occurrence(
            in: 12,
            context: context
        )

        XCTAssertEqual(
            calendar.component(.day, from: savedNovember.dueDate),
            20
        )
        XCTAssertEqual(
            calendar.component(.day, from: savedDecember.dueDate),
            20
        )

        // Yeni yılın ilk ödemesi de yeni tarihle oluşmalı.
        try PaymentOccurrenceService.generateOccurrences(
            for: makeDate(2027, 1, 1),
            context: context
        )

        let january = try occurrence(
            in: 1,
            year: 2027,
            context: context
        )

        XCTAssertEqual(
            calendar.component(.day, from: january.dueDate),
            20
        )
        XCTAssertEqual(
            try occurrences(in: context).count,
            4
        )
    }

    // Aralık önceden ödenmişse Kasım'dan itibaren
    // toplu tarih değişikliğine izin verilmemeli.
    func testFuturePaidOccurrencePreventsRescheduling() throws {

        let context = try makeContext()
        let payment = makePayment()

        context.insert(payment)
        try context.save()

        for month in 10...12 {
            try PaymentOccurrenceService.generateOccurrences(
                for: makeDate(2026, month, 1),
                context: context
            )
        }

        let december = try occurrence(
            in: 12,
            context: context
        )

        december.isPaid = true
        december.paidDate = makeDate(2026, 12, 15)
        try context.save()

        let november = try occurrence(
            in: 11,
            context: context
        )

        XCTAssertThrowsError(
            try PaymentSeriesEditService.changeFutureDates(
                occurrence: november,
                newDate: makeDate(2026, 11, 20),
                context: context
            )
        ) { error in
            guard case PaymentSeriesEditError.futurePaidOccurrence = error
            else {
                XCTFail("Beklenmeyen hata: \(error)")
                return
            }
        }

        let savedNovember = try occurrence(
            in: 11,
            context: context
        )

        let savedDecember = try occurrence(
            in: 12,
            context: context
        )

        XCTAssertEqual(
            calendar.component(.day, from: savedNovember.dueDate),
            15
        )
        XCTAssertEqual(
            calendar.component(.day, from: savedDecember.dueDate),
            15
        )
        XCTAssertTrue(savedDecember.isPaid)

        XCTAssertEqual(
            try context.fetch(FetchDescriptor<Payment>()).count,
            1
        )
    }
    
    // Geçersiz tarihte kayıtlar değişmeden korunmalı.
    func testInvalidDateDoesNotModifyPayments() throws {

        let context = try makeContext()
        let payment = makePayment()

        context.insert(payment)
        try context.save()

        // Kasım ödemesini oluştur.
        try PaymentOccurrenceService.generateOccurrences(
            for: makeDate(2026, 11, 1),
            context: context
        )

        let november = try occurrence(
            in: 11,
            context: context
        )

        let originalDate = november.dueDate
        let originalPaymentID = november.paymentID

        // Kasım ödemesini yanlışlıkla Aralık'a taşımayı dene.
        XCTAssertThrowsError(
            try PaymentSeriesEditService.changeFutureDates(
                occurrence: november,
                newDate: makeDate(2026, 12, 20),
                context: context
            )
        ) { error in
            guard case PaymentSeriesEditError.invalidDate = error else {
                XCTFail("Beklenmeyen hata: \(error)")
                return
            }
        }

        // Kayıt hâlâ aynı tarihte kalmalı.
        let savedNovember = try occurrence(
            in: 11,
            context: context
        )

        XCTAssertEqual(savedNovember.dueDate, originalDate)
        XCTAssertEqual(savedNovember.paymentID, originalPaymentID)

        // Yeni bir ödeme serisi oluşmamalı.
        let payments = try context.fetch(
            FetchDescriptor<Payment>()
        )

        XCTAssertEqual(payments.count, 1)
    }

}

