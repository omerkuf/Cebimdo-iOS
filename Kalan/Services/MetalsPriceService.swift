//
//  MetalsPriceService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct MetalsPriceResponse: Decodable {
    let goldTRYPerGram: Decimal
    let silverTRYPerGram: Decimal
    let updatedAt: String?
}

struct MetalsPriceService {

    private let endpoint = URL(
        string: "https://kalan-market-api.kilicaslanomerkuf.workers.dev/metals"
    )!

    func fetchPrices() async throws -> MetalsPriceResponse {

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(
            MetalsPriceResponse.self,
            from: data
        )

        guard result.goldTRYPerGram > 0,
              result.silverTRYPerGram > 0 else {
            throw URLError(.cannotParseResponse)
        }

        return result
    }
}
