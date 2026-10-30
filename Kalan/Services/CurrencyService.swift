//
//  CurrencyService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct CurrencyRateResponse: Decodable {
    let date: String
    let base: String
    let quote: String
    let rate: Decimal
}

struct CurrencyRateSnapshot {
    let rates: [String: Decimal]
    let date: String
}

struct CurrencyService {

    func fetchRates() async throws -> CurrencyRateSnapshot {

        let url = URL(
            string: "https://api.frankfurter.dev/v2/rates?base=USD&quotes=TRY,EUR,GBP,CHF"
        )!

        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let items = try JSONDecoder().decode(
            [CurrencyRateResponse].self,
            from: data
        )

        var rates: [String: Decimal] = [
            "USD": 1
        ]

        for item in items where item.base.uppercased() == "USD" {
            guard item.rate > 0 else { continue }
            rates[item.quote.uppercased()] = item.rate
        }

        guard rates["TRY"] != nil,
              rates["EUR"] != nil,
              rates["GBP"] != nil,
              rates["CHF"] != nil,
              let date = items.first?.date else {
            throw URLError(.cannotParseResponse)
        }

        return CurrencyRateSnapshot(
            rates: rates,
            date: date
        )
    }
}
