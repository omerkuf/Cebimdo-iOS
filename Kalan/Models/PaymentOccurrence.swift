//
//  PaymentOccurrence.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation
import SwiftData

@Model
final class PaymentOccurrence {

    @Attribute(.unique) var id: UUID

    var paymentID: UUID
    var dueDate: Date
    var scheduledDate: Date?
    var amount: Decimal
    var name: String
    var isPaid: Bool
    var paidDate: Date?

    init(
        paymentID: UUID,
        dueDate: Date,
        amount: Decimal,
        name: String,
        isPaid: Bool = false,
        paidDate: Date? = nil
    ) {
        self.id = UUID()
        self.paymentID = paymentID
        self.dueDate = dueDate
        self.scheduledDate = dueDate
        self.amount = amount
        self.name = name
        self.isPaid = isPaid
        self.paidDate = paidDate
    }
}
