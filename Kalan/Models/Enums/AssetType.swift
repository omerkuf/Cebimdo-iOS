//
//  AssetType.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

enum AssetType: String, Codable, CaseIterable, Identifiable {

    case gold
    case silver
    case usd
    case eur
    case gbp
    case chf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gold: return "Gram Altın"
        case .silver: return "Gram Gümüş"
        case .usd: return "Amerikan Doları"
        case .eur: return "Euro"
        case .gbp: return "İngiliz Sterlini"
        case .chf: return "İsviçre Frangı"
        }
    }

    var symbol: String {
        switch self {
        case .gold: return "XAU"
        case .silver: return "XAG"
        case .usd: return "USD"
        case .eur: return "EUR"
        case .gbp: return "GBP"
        case .chf: return "CHF"
        }
    }

    var unit: String {
        switch self {
        case .gold, .silver:
            return "gram"
        default:
            return "birim"
        }
    }

    var icon: String {
        switch self {
        case .gold: return "circle.hexagongrid.fill"
        case .silver: return "circle.grid.2x2.fill"
        default: return "banknote"
        }
    }

    var category: String {
        switch self {
        case .gold, .silver: return "Değerli Madenler"
        default: return "Döviz"
        }
    }
}
