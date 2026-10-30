//
//  PaymentRow.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI

struct PaymentRow: View {

    let payment: DemoPayment
    let onEdit: () -> Void
    let onTogglePaid: () -> Void

    var body: some View {
        HStack(spacing: 10) {

            Image(
                systemName: payment.isPaid
                    ? "checkmark.circle.fill"
                    : "doc.text"
            )
            .foregroundStyle(
                payment.isPaid ? .green : .secondary
            )
            .frame(width: 32, height: 32)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(payment.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(
                    payment.dueDate.formatted(
                        .dateTime.day().month(.wide)
                            .locale(Locale(identifier: "tr_TR"))
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(
                    payment.amount.formatted(
                        .currency(code: "TRY")
                            .locale(Locale(identifier: "tr_TR"))
                    )
                )
                .font(.caption.weight(.semibold))
            }

            Spacer(minLength: 4)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .accessibilityLabel("Ödemeyi düzenle")

            Button(action: onTogglePaid) {
                Text(payment.isPaid ? "Geri Al" : "Ödendi")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(payment.isPaid ? .gray : .blue)
        }
        .padding(.vertical, 6)
    }
}
