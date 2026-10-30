//
//  AssetsViewModel.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation
import Combine

@MainActor
final class AssetsViewModel: ObservableObject {

    @Published private(set) var rates: [String: Decimal] = [:]
    @Published private(set) var lastUpdated: String?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let currencyService = CurrencyService()

    func fetchPrices() async {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let result = try await currencyService.fetchRates()

            rates = result.rates
            lastUpdated = result.date

        } catch {
            errorMessage = "Döviz kurları alınamadı. Lütfen tekrar deneyin."
        }
    }

    func convertedAmount(
        quantity: Decimal,
        symbol: String,
        targetCurrency: String
    ) -> Decimal? {

        let source = symbol.uppercased()
        let target = targetCurrency.uppercased()

        // Altın ve gümüş fiyatlarını sonraki bağlantıda ekleyeceğiz.
        guard source != "XAU", source != "XAG" else {
            return nil
        }

        guard let sourceRate = rates[source],
              let targetRate = rates[target],
              sourceRate > 0 else {
            return nil
        }

        return (quantity / sourceRate) * targetRate
    }

    func formattedAmount(
        _ amount: Decimal,
        currency: String
    ) -> String {

        amount.formatted(
            .currency(code: currency)
                .locale(Locale(identifier: "tr_TR"))
        )
    }
}
