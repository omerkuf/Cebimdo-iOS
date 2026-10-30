//
//  PaymentOccurrenceService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation
import SwiftData

struct PaymentOccurrenceService {

    static func generateOccurrences(
        for month: Date,
        context: ModelContext
    ) throws {

        let payments = try context.fetch(
            FetchDescriptor<Payment>()
        )

        let existingOccurrences = try context.fetch(
            FetchDescriptor<PaymentOccurrence>()
        )

        let calendar = Calendar.current

        for payment in payments {

            let recurrence = RecurrenceType(
                rawValue: payment.recurrence
            ) ?? .once

            let dates = RecurrenceService.dates(
                in: month,
                from: payment.startDate,
                recurrence: recurrence,
                endDate: payment.endDate
            )

            for date in dates {

                let alreadyExists = existingOccurrences.contains {
                    $0.paymentID == payment.id &&
                    calendar.isDate(
                        $0.scheduledDate ?? $0.dueDate,
                        inSameDayAs: date
                    )
                }

                guard !alreadyExists else {
                    continue
                }

                let occurrence = PaymentOccurrence(
                    paymentID: payment.id,
                    dueDate: date,
                    amount: payment.amount,
                    name: payment.name
                )

                context.insert(occurrence)
            }
        }

        try context.save()
    }
}
