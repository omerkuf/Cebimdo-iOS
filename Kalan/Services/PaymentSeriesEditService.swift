//
//  PaymentSeriesEditService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import Foundation
import SwiftData

enum PaymentSeriesEditError: LocalizedError {
    case paymentNotFound
    case unsupportedRecurrence
    case invalidDate
    case futurePaidOccurrence

    var errorDescription: String? {
        switch self {
        case .paymentNotFound:
            return "Ödeme tanımı bulunamadı."
        case .unsupportedRecurrence:
            return "Toplu tarih değişikliği şu anda yalnızca aylık ödemelerde kullanılabilir."
        case .invalidDate:
            return "Yeni ödeme tarihi seçili ay içerisinde olmalıdır."
        case .futurePaidOccurrence:
            return "Seçili veya sonraki dönemlerde ödenmiş kayıt var. Ödenmiş faturaların tarihleri topluca değiştirilemez."
        }
    }
}

struct PaymentSeriesEditService {

    static func changeFutureDates(
        occurrence: PaymentOccurrence,
        newDate: Date,
        newAmount: Decimal,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws {

        let payments = try context.fetch(
            FetchDescriptor<Payment>()
        )

        guard let payment = payments.first(where: {
            $0.id == occurrence.paymentID
        }) else {
            throw PaymentSeriesEditError.paymentNotFound
        }

        guard RecurrenceType(rawValue: payment.recurrence) == .monthly else {
            throw PaymentSeriesEditError.unsupportedRecurrence
        }

        let originalDate = calendar.startOfDay(
            for: occurrence.scheduledDate ?? occurrence.dueDate
        )

        let newDay = calendar.startOfDay(for: newDate)

        guard calendar.isDate(
            originalDate,
            equalTo: newDay,
            toGranularity: .month
        ) else {
            throw PaymentSeriesEditError.invalidDate
        }

        let allOccurrences = try context.fetch(
            FetchDescriptor<PaymentOccurrence>()
        )

        let futureOccurrences = allOccurrences.filter {
            $0.paymentID == payment.id &&
            calendar.startOfDay(
                for: $0.scheduledDate ?? $0.dueDate
            ) >= originalDate
        }

        guard !futureOccurrences.contains(where: \.isPaid) else {
            throw PaymentSeriesEditError.futurePaidOccurrence
        }

        let newPaymentDay = calendar.component(
            .day,
            from: newDay
        )

        // Önceki serinin yalnızca geçmiş bölümü kalır.
        guard let oldSeriesEnd = calendar.date(
            byAdding: .day,
            value: -1,
            to: originalDate
        ) else {
            throw PaymentSeriesEditError.invalidDate
        }

        // Kullanıcının seçtiği tarihte yeni bir seri başlatılır.
        let newPayment = Payment(
            name: payment.name,
            amount: newAmount,
            category: payment.category,
            startDate: newDay,
            recurrence: .monthly,
            endDate: payment.endDate,
            note: payment.note
        )

        // Mevcut serinin önceden planlanan bitişini koruruz.
        if let endDate = payment.endDate {
            guard newDay <= endDate else {
                throw PaymentSeriesEditError.invalidDate
            }
        }

        context.insert(newPayment)

        // Eski serinin önceki bitiş tarihini de dikkate al.
        if let previousEnd = payment.endDate {
            payment.endDate = min(previousEnd, oldSeriesEnd)
        } else {
            payment.endDate = oldSeriesEnd
        }

        for item in futureOccurrences {

            let originalScheduledDate =
                item.scheduledDate ?? item.dueDate

            let monthComponents = calendar.dateComponents(
                [.year, .month],
                from: originalScheduledDate
            )

            guard let monthStart = calendar.date(
                from: monthComponents
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: monthStart
            ),
            let newScheduledDate = calendar.date(
                byAdding: .day,
                value: min(newPaymentDay, dayRange.count) - 1,
                to: monthStart
            ) else {
                throw PaymentSeriesEditError.invalidDate
            }

            // Ödeme bilgileri ve ödenme durumu korunur.
            // Yalnızca bağlı seri ve tarih değiştirilir.
            item.paymentID = newPayment.id
            item.scheduledDate = newScheduledDate
            item.dueDate = newScheduledDate
            item.amount = newAmount
        }

        try context.save()
    }
}
