//
//  ChatAssetService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//

import Foundation

struct ChatAssetService {

    static func answer(
        intent: ChatIntentResult,
        assets: [AssetHolding],
        viewModel: AssetsViewModel
    ) -> String {

        let locale = Locale(identifier: "tr_TR")

        func currency(_ amount: Decimal) -> String {
            amount.formatted(
                .currency(code: "TRY").locale(locale)
            )
        }

        func quantity(_ amount: Decimal) -> String {
            amount.formatted(
                .number
                    .precision(.fractionLength(0...2))
                    .locale(locale)
            )
        }

        func assetName(_ symbol: String) -> String {
            switch symbol {
            case "XAU": return "gram altın"
            case "XAG": return "gram gümüş"
            case "USD": return "Amerikan doları"
            case "EUR": return "euro"
            case "GBP": return "İngiliz sterlini"
            case "CHF": return "İsviçre frangı"
            default: return symbol
            }
        }

        func unit(_ symbol: String) -> String {
            symbol == "XAU" || symbol == "XAG"
                ? "gram"
                : symbol
        }

        guard !assets.isEmpty else {
            return "Henüz kayıtlı varlığın bulunmuyor. Varlıklarım ekranından varlık ekleyebilirsin."
        }

        switch intent.intent {

        case .portfolioTotal:

            let values = assets.compactMap { asset in
                viewModel.convertedAmount(
                    quantity: asset.quantity,
                    symbol: asset.symbol,
                    targetCurrency: "TRY"
                )
            }

            guard values.count == assets.count else {
                return "Portföyün toplam değerini şu anda hesaplayamıyorum. Piyasa verilerini yenilemeyi deneyebilirsin."
            }

            let total = values.reduce(Decimal.zero, +)

            return "Portföyünün güncel tahmini toplam değeri \(currency(total)). Toplam \(assets.count) varlık kaydın bulunuyor."

        case .assetQuantity, .assetValue:

            guard let symbol = intent.assetSymbol?.uppercased(),
                  ["XAU", "XAG", "USD", "EUR", "GBP", "CHF"].contains(symbol) else {
                return "Hangi varlığını öğrenmek istediğini anlayamadım. Altın, gümüş, dolar veya euro gibi bir varlık belirtebilirsin."
            }

            let matching = assets.filter {
                $0.symbol.uppercased() == symbol
            }

            guard !matching.isEmpty else {
                return "Portföyünde kayıtlı \(assetName(symbol)) bulunmuyor."
            }

            let totalQuantity = matching.reduce(Decimal.zero) {
                $0 + $1.quantity
            }

            if intent.intent == .assetQuantity {
                return "Portföyünde \(quantity(totalQuantity)) \(unit(symbol)) \(assetName(symbol)) bulunuyor."
            }

            let values = matching.compactMap { asset in
                viewModel.convertedAmount(
                    quantity: asset.quantity,
                    symbol: asset.symbol,
                    targetCurrency: "TRY"
                )
            }

            guard values.count == matching.count else {
                return "\(assetName(symbol)) varlığının miktarı \(quantity(totalQuantity)) \(unit(symbol)), ancak güncel TL karşılığını hesaplamak için piyasa verilerine ulaşamadım."
            }

            let total = values.reduce(Decimal.zero, +)

            return "Portföyünde \(quantity(totalQuantity)) \(unit(symbol)) \(assetName(symbol)) bulunuyor. Güncel tahmini TL karşılığı \(currency(total))."

        case .assetList:

            var lines: [String] = []
            var hasUnavailablePrice = false

            for asset in assets {
                if let value = viewModel.convertedAmount(
                    quantity: asset.quantity,
                    symbol: asset.symbol,
                    targetCurrency: "TRY"
                ) {
                    lines.append(
                        "\(asset.name): \(quantity(asset.quantity)) \(asset.unit) — \(currency(value))"
                    )
                } else {
                    hasUnavailablePrice = true
                    lines.append(
                        "\(asset.name): \(quantity(asset.quantity)) \(asset.unit) — fiyat bilgisi yok"
                    )
                }
            }

            let header = "Portföyündeki varlıkların:"

            let footer = hasUnavailablePrice
                ? "\nBazı varlıkların güncel değerleri hesaplanamadı."
                : ""

            return header + "\n\n"
                + lines.joined(separator: "\n")
                + footer

        default:
            return "Bu varlık sorgusunu şu anda cevaplayamıyorum."
        }
    }
}

