//
//  ChatIntent.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//

import Foundation

enum ChatQuestionType: String, Codable {
    case monthlyIncome = "monthly_income"
    case paidPayments = "paid_payments"
    case plannedPayments = "planned_payments"
    case remainingBudget = "remaining_budget"
    case topCategory = "top_category"
    case comparePreviousMonth = "compare_previous_month"
    case unsupported
}

struct ChatIntentResult: Decodable {
    let intent: ChatQuestionType
    let month: String
}

struct ChatIntentRequest: Encodable {
    let text: String
    let referenceDate: String
}

