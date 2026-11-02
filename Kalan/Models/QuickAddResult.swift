//
//  QuickAddResult.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//

import Foundation

struct QuickAddResult: Decodable {
    let transactionType: String
    let name: String
    let amount: Decimal
    let category: String
    let recurrence: String
    let date: String
}

struct QuickAddRequest: Encodable {
    let text: String
    let referenceDate: String
    let transactionType: String
}

