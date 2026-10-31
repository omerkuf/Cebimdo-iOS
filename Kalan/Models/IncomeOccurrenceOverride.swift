//
//  IncomeOccurrenceOverride.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import Foundation
import SwiftData

@Model
final class IncomeOccurrenceOverride {

    @Attribute(.unique) var id: UUID
    var incomeID: UUID
    var occurrenceDate: Date
    var amount: Decimal

    init(incomeID: UUID, occurrenceDate: Date, amount: Decimal) {
        self.id = UUID()
        self.incomeID = incomeID
        self.occurrenceDate = occurrenceDate
        self.amount = amount
    }
}
