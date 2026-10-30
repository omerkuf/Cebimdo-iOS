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
    
    @Published private(set) var metals: MetalsPriceResponse?
    @Published private(set) var metalsErrorMessage: String?

    private let currencyService = CurrencyService()
    private let metalsService = MetalsPriceService()
    
    func fetchMetals() async {
        metalsErrorMessage = nil

        do {
            metals = try await metalsService.fetchPrices()
        } catch {
            metalsErrorMessage = "Altın ve gümüş fiyatları alınamadı."
        }
    }

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

        guard let targetRate = rates[target],
              targetRate > 0 else {
            return nil
        }

        if source == "XAU" || source == "XAG" {

            guard let metals,
                  let tryRate = rates["TRY"],
                  tryRate > 0 else {
                return nil
            }

            let gramPriceTRY = source == "XAU"
                ? metals.goldTRYPerGram
                : metals.silverTRYPerGram

            let totalTRY = quantity * gramPriceTRY

            return (totalTRY / tryRate) * targetRate
        }

        guard let sourceRate = rates[source],
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
