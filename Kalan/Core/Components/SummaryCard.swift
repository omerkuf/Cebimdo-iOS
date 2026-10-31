//
//  SummaryCard.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI

struct SummaryCard: View {

    let title: String
    let amount: Decimal
    let icon: String
    let color: Color
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(
                amount.formatted(
                    .currency(code: "TRY")
                        .locale(Locale(identifier: "tr_TR"))
                )
            )
            .font(.system(size: 21, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .allowsTightening(true)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .shadow(
            color: .black.opacity(0.025),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}
