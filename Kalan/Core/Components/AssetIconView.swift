//
//  AssetIconView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 1.11.2026.
//

import SwiftUI

struct AssetIconView: View {

    let symbol: String
    var size: CGFloat = 40

    private var type: String {
        symbol.uppercased()
    }

    private var iconColor: Color {
        switch type {
        case "XAU":
            return Color(red: 0.88, green: 0.62, blue: 0.06)
        case "XAG":
            return Color(red: 0.48, green: 0.53, blue: 0.59)
        case "GBP":
            return Color(red: 0.43, green: 0.30, blue: 0.70)
        case "CHF":
            return Color(red: 0.85, green: 0.26, blue: 0.32)
        default:
            return Color(red: 0.06, green: 0.48, blue: 0.26)
        }
    }

    private var currencySymbol: String? {
        switch type {
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "CHF":
            return "Fr"
        default:
            return nil
        }
    }

    private var iconName: String {
        switch type {
        case "XAU":
            return "circle.hexagongrid.fill"
        case "XAG":
            return "square.stack.3d.up.fill"
        default:
            return "wallet.pass.fill"
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(iconColor.opacity(0.10))

            if let currencySymbol {
                Text(currencySymbol)
                    .font(
                        .custom(
                            "AvenirNext-Bold",
                            size: size * (type == "CHF" ? 0.34 : 0.52)
                        )
                    )
                    .foregroundStyle(iconColor)
            } else {
                Image(systemName: iconName)
                    .font(
                        .system(
                            size: size * 0.46,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(iconColor)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
