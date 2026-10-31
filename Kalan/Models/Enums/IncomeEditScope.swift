//
//  IncomeEditScope.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import Foundation

enum IncomeEditScope: String, CaseIterable, Identifiable {
    case onlyThis
    case thisAndFuture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .onlyThis:
            return "Yalnızca Bu Gelir"
        case .thisAndFuture:
            return "Bu ve Sonraki Gelirler"
        }
    }

    var description: String {
        switch self {
        case .onlyThis:
            return "Sadece seçilen dönemin tutarı değişir."
        case .thisAndFuture:
            return "Bu tarihten itibaren tekrarlayan gelir tutarı değişir."
        }
    }
}
