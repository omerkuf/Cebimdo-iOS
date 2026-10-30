//
//  IncomeAmountChange.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation
import SwiftData

@Model
final class IncomeAmountChange {

    @Attribute(.unique) var id: UUID

    var incomeID: UUID
    var effectiveDate: Date
    var amount: Decimal
    var createdAt: Date

    init(
        incomeID: UUID,
        effectiveDate: Date,
        amount: Decimal
    ) {
        self.id = UUID()
        self.incomeID = incomeID
        self.effectiveDate = effectiveDate
        self.amount = amount
        self.createdAt = Date()
    }
}
