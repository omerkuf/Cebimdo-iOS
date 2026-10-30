//
//  AssetHolding.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation
import SwiftData

@Model
final class AssetHolding {

    @Attribute(.unique) var id: UUID

    var name: String
    var symbol: String
    var quantity: Decimal
    var unit: String
    var createdAt: Date
    var updatedAt: Date?

    init(
        name: String,
        symbol: String,
        quantity: Decimal,
        unit: String
    ) {
        self.id = UUID()
        self.name = name
        self.symbol = symbol
        self.quantity = quantity
        self.unit = unit
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
