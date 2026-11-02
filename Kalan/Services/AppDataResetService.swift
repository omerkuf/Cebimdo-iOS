//
//  AppDataResetService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//


import Foundation
import SwiftData

enum AppDataResetService {

    @MainActor
    static func reset(context: ModelContext) throws {

        // Gelirler
        try context.delete(
            model: Income.self
        )

        // Gelirlerin geleceğe dönük tutar değişiklikleri
        try context.delete(
            model: IncomeAmountChange.self
        )

        // Tek bir gelir dönemine ait özel tutarlar
        try context.delete(
            model: IncomeOccurrenceOverride.self
        )

        // Ödemeler
        try context.delete(
            model: Payment.self
        )

        // Ödenmiş ve ödenmemiş ödeme kayıtları
        try context.delete(
            model: PaymentOccurrence.self
        )

        // Altın, gümüş ve döviz varlıkları
        try context.delete(
            model: AssetHolding.self
        )

        // Silme işlemlerini kaydet
        try context.save()
    }
}

