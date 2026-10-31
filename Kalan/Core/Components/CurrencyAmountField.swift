//
//  CurrencyAmountField.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 31.10.2026.
//


import SwiftUI

struct CurrencyAmountField: View {

    let title: String
    @Binding var amount: Decimal

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onAppear {
                text = formattedAmount
            }
            .onChange(of: amount) { _, _ in
                if !isFocused {
                    text = formattedAmount
                }
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    text = amount == .zero
                        ? ""
                        : editingAmount
                } else {
                    text = formattedAmount
                }
            }
            .onChange(of: text) { _, newValue in
                guard isFocused else { return }

                let cleaned = String(
                    newValue.filter {
                        $0.isNumber || $0 == "," || $0 == "."
                    }
                )

                if cleaned != newValue {
                    text = cleaned
                    return
                }

                if cleaned.isEmpty {
                    amount = .zero
                    return
                }

                if let value = parseAmount(cleaned) {
                    amount = value
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Tamam") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
    }

    private var formattedAmount: String {
        guard amount != .zero else { return "" }

        return amount.formatted(
            .number
                .grouping(.automatic)
                .precision(.fractionLength(0...2))
                .locale(Locale(identifier: "tr_TR"))
        )
    }

    private var editingAmount: String {
        amount.formatted(
            .number
                .grouping(.never)
                .precision(.fractionLength(0...2))
                .locale(Locale(identifier: "tr_TR"))
        )
    }

    private func parseAmount(_ input: String) -> Decimal? {

        let separators = input.enumerated().filter {
            $0.element == "," || $0.element == "."
        }

        let decimalIndex: Int?

        if let last = separators.last {

            let digitsAfter = input.count - last.offset - 1

            // Türkçe binlik ayıracı: 1.500
            if separators.count == 1 &&
               last.element == "." &&
               digitsAfter == 3 {
                decimalIndex = nil
            } else {
                decimalIndex = last.offset
            }

        } else {
            decimalIndex = nil
        }

        var normalized = ""
        var fractionDigits = 0

        for (index, character) in input.enumerated() {

            if character.isNumber {
                normalized.append(character)

                if let decimalIndex, index > decimalIndex {
                    fractionDigits += 1
                }

            } else if index == decimalIndex {
                normalized.append(".")
            }
        }

        guard fractionDigits <= 2 else {
            return nil
        }

        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }
}

