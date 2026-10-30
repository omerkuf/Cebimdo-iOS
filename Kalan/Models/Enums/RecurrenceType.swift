//
//  RecurrenceType.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

enum RecurrenceType: String, Codable, CaseIterable, Identifiable {
    case once
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .once: return "Tek Seferlik"
        case .weekly: return "Her Hafta"
        case .monthly: return "Her Ay"
        case .yearly: return "Her Yıl"
        }
    }
}
