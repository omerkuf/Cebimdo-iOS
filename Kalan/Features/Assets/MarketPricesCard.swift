//
//  MarketPricesCard.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 3.11.2026.
//

import SwiftUI

struct MarketPricesCard: View {

    @ObservedObject var assetsViewModel: AssetsViewModel

    private let green = Color(
        red: 15 / 255.0,
        green: 122 / 255.0,
        blue: 67 / 255.0
    )

    private let items: [
        (name: String, symbol: String, icon: String, color: Color)
    ] = [
        ("Dolar", "USD", "dollarsign", .green),
        ("Euro", "EUR", "eurosign", .blue),
        ("Gram Altın", "XAU", "circle.hexagongrid.fill", .orange),
        ("Gram Gümüş", "XAG", "square.stack.3d.up.fill", .gray)
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Piyasa Fiyatları")
                    .font(.custom("AvenirNext-DemiBold", size: 17))

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundStyle(green)
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(items, id: \.symbol) { item in
                    priceRow(
                        name: item.name,
                        symbol: item.symbol,
                        icon: item.icon,
                        color: item.color
                    )
                }
            }

            Text("Son alınan piyasa verileri · Tahmini fiyatlar")
                .font(.custom("AvenirNext-Regular", size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
        .shadow(
            color: green.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    private func priceRow(
        name: String,
        symbol: String,
        icon: String,
        color: Color
    ) -> some View {

        let price = assetsViewModel.convertedAmount(
            quantity: Decimal(1),
            symbol: symbol,
            targetCurrency: "TRY"
        )

        return HStack(spacing: 8) {

            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(color.opacity(0.10))
                )

            VStack(alignment: .leading, spacing: 2) {

                Text(name)
                    .font(.custom("AvenirNext-Medium", size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let price {
                    Text(
                        price.formatted(
                            .currency(code: "TRY")
                                .locale(Locale(identifier: "tr_TR"))
                        )
                    )
                    .font(.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                } else {
                    Text("Veri yok")
                        .font(.custom("AvenirNext-Medium", size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

