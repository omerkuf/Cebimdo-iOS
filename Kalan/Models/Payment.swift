//
//  Payment.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation
import SwiftData

@Model
final class Payment {

    @Attribute(.unique) var id: UUID

    var name: String
    var amount: Decimal
    var category: String
    var startDate: Date
    var recurrence: String
    var endDate: Date?
    var note: String
    var createdAt: Date

    init(
        name: String,
        amount: Decimal,
        category: String,
        startDate: Date,
        recurrence: RecurrenceType = .once,
        endDate: Date? = nil,
        note: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.startDate = startDate
        self.recurrence = recurrence.rawValue
        self.endDate = endDate
        self.note = note
        self.createdAt = Date()
    }
}
