//
//  IncomeSeriesEditService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//

import Foundation
import SwiftData

enum IncomeSeriesEditService {

    static func updateThisAndFuture(
        income: Income,
        effectiveDate: Date,
        amount: Decimal,
        changes: [IncomeAmountChange],
        overrides: [IncomeOccurrenceOverride],
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let effectiveDay = calendar.startOfDay(for: effectiveDate)

        // Seçilen dönemden sonraki eski genel tutar değişikliklerini sil.
        let futureChanges = changes.filter {
            $0.incomeID == income.id &&
            calendar.startOfDay(for: $0.effectiveDate) >= effectiveDay
        }

        futureChanges.forEach {
            context.delete($0)
        }

        // Seçilen dönemden sonraki özel tutarları da sil.
        let futureOverrides = overrides.filter {
            $0.incomeID == income.id &&
            calendar.startOfDay(for: $0.occurrenceDate) >= effectiveDay
        }

        futureOverrides.forEach {
            context.delete($0)
        }

        // Yeni tutarı seçilen tarihten itibaren geçerli kıl.
        context.insert(
            IncomeAmountChange(
                incomeID: income.id,
                effectiveDate: effectiveDay,
                amount: amount
            )
        )
    }
}

