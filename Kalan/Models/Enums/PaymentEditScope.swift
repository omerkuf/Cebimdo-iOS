//
//  PaymentEditScope.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import Foundation

enum PaymentEditScope: String, CaseIterable, Identifiable {
    case onlyThis
    case thisAndFuture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onlyThis:
            return "Yalnızca Bu Ödeme"
        case .thisAndFuture:
            return "Bu ve Sonraki Ödemeler"
        }
    }

    var description: String {
        switch self {
        case .onlyThis:
            return "Sadece seçili faturayı değiştirir."
        case .thisAndFuture:
            return "Seçili ay ve sonraki ayların ödeme gününü değiştirir."
        }
    }
}
