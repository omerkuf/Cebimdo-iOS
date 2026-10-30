//
//  AddAssetView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct AddAssetView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let asset: AssetHolding?

    @State private var selectedType: AssetType = .gold
    @State private var quantityText = ""

    @State private var showError = false
    @State private var errorMessage = ""

    init(asset: AssetHolding? = nil) {
        self.asset = asset
    }

    private var parsedQuantity: Decimal? {
        let normalized = quantityText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    private var canSave: Bool {
        (parsedQuantity ?? .zero) > .zero
    }

    var body: some View {
        NavigationStack {
            Form {

                Section("Varlık Türü") {
                    Picker("Varlık", selection: $selectedType) {
                        ForEach(AssetType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .disabled(asset != nil)
                }

                Section("Miktar") {
                    HStack {
                        TextField(
                            "Miktar girin",
                            text: $quantityText
                        )
                        .keyboardType(.decimalPad)

                        Text(selectedType.unit)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: selectedType.icon)
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedType.title)
                                .font(.headline)

                            Text(
                                "Güncel TL karşılığı piyasa verileri " +
                                "bağlandığında görüntülenecek."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }

                Section {
                    Button {
                        saveAsset()
                    } label: {
                        Text(
                            asset == nil
                                ? "Varlığı Kaydet"
                                : "Değişiklikleri Kaydet"
                        )
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle(
                asset == nil ? "Varlık Ekle" : "Varlığı Düzenle"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAsset()
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func loadAsset() {
        guard let asset else { return }

        selectedType = AssetType(rawValue: asset.symbol.lowercased())
            ?? .gold

        quantityText = NSDecimalNumber(
            decimal: asset.quantity
        ).stringValue
    }

    private func saveAsset() {
        guard let quantity = parsedQuantity,
              quantity > .zero else {
            return
        }

        do {
            if let asset {
                asset.quantity = quantity
                asset.updatedAt = Date()
            } else {
                let newAsset = AssetHolding(
                    name: selectedType.title,
                    symbol: selectedType.symbol,
                    quantity: quantity,
                    unit: selectedType.unit
                )

                modelContext.insert(newAsset)
            }

            try modelContext.save()
            dismiss()

        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
