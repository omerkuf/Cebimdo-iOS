//
//  ChatHintBubble.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 3.11.2026.
//

import SwiftUI

struct ChatHintBubble: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Cebimdo Chat'a sordun mu?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Hızlı sorularla gelirini, harcamanı ve bütçeni anında öğren.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.green.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
