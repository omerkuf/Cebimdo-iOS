//
//  AssetsView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct AssetsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \AssetHolding.createdAt, order: .reverse)
    private var assets: [AssetHolding]
    
    @ObservedObject var viewModel: AssetsViewModel
    
    @State private var selectedCurrency = "TRY"

    @State private var showAddAsset = false
    @State private var selectedAsset: AssetHolding?

    @State private var assetToDelete: AssetHolding?
    @State private var showDeleteConfirmation = false

    @State private var showError = false
    @State private var errorMessage = ""
    
    private let supportedCurrencies = [
        "TRY", "USD", "EUR"
    ]

    private var portfolioTotal: Decimal? {

        guard !assets.isEmpty else {
            return nil
        }

        let values = assets.compactMap { asset in
            viewModel.convertedAmount(
                quantity: asset.quantity,
                symbol: asset.symbol,
                targetCurrency: selectedCurrency
            )
        }

        guard values.count == assets.count else {
            return nil
        }

        return values.reduce(.zero, +)
    }

    private var preciousMetals: [AssetHolding] {
        assets.filter {
            $0.symbol == "XAU" || $0.symbol == "XAG"
        }
    }

    private var currencies: [AssetHolding] {
        assets.filter {
            $0.symbol != "XAU" && $0.symbol != "XAG"
        }
    }
    
    private func parseMarketDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter.date(from: value)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    portfolioSummary

                    if assets.isEmpty {
                        emptyState
                    } else {

                        if !preciousMetals.isEmpty {
                            assetSection(
                                title: "Değerli Madenler",
                                items: preciousMetals
                            )
                        }

                        if !currencies.isEmpty {
                            assetSection(
                                title: "Dövizler",
                                items: currencies
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Varlıklarım")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAsset = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Yeni varlık ekle")
                }
            }
            .sheet(isPresented: $showAddAsset) {
                AddAssetView()
            }
            .sheet(item: $selectedAsset) { asset in
                AddAssetView(asset: asset)
            }
            .alert(
                "Varlığı Sil",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Vazgeç", role: .cancel) {
                    assetToDelete = nil
                }

                Button("Sil", role: .destructive) {
                    deleteAsset()
                }
            } message: {
                Text("Bu varlık kaydı kalıcı olarak silinecek.")
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var portfolioSummary: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Portföyüm")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(
                "Görüntüleme Para Birimi",
                selection: $selectedCurrency
            ) {
                ForEach(supportedCurrencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(.segmented)

            if let portfolioTotal {

                Text(
                    viewModel.formattedAmount(
                        portfolioTotal,
                        currency: selectedCurrency
                    )
                )
                .font(.system(size: 28, weight: .bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

                Text("Toplam tahmini portföy değeri")
                    .font(.caption)
                    .foregroundStyle(.secondary)

            } else {

                Text("Henüz hesaplanmadı")
                    .font(.title2.bold())

                Text("Döviz fiyatları henüz alınamadı.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isLoading {
                ProgressView("Kurlar güncelleniyor...")
                    .font(.caption)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let lastUpdated = viewModel.lastUpdated {
                Text("Kur tarihi: \(lastUpdated)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Altın ve gümüş fiyatı güncelleme tarihi
            // Altın ve gümüş fiyatı güncelleme tarihi
            if let updatedAt = viewModel.metals?.updatedAt,
               let date = parseMarketDate(updatedAt) {

                let formattedDate = date.formatted(
                    .dateTime
                        .day()
                        .month(.wide)
                        .hour()
                        .minute()
                        .locale(Locale(identifier: "tr_TR"))
                )

                Text("Maden fiyatı: \(formattedDate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "wallet.pass")
                    .foregroundStyle(.blue)

                Text("\(assets.count) varlık kaydı")
                    .font(.caption.weight(.medium))

                Spacer()

                Button {
                    Task {
                        await viewModel.refreshIfNeeded(
                            needsMetals: assets.contains {
                                $0.symbol == "XAU" || $0.symbol == "XAG"
                            },
                            force: true
                        )
                    }
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {

            Image(systemName: "tray")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text("Henüz Varlık Eklenmedi")
                .font(.headline)

            Text(
                "Altın, gümüş veya döviz varlıklarınızı " +
                "ekleyerek portföyünüzü oluşturmaya başlayın."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button {
                showAddAsset = true
            } label: {
                Label("Varlık Ekle", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    private func assetSection(
        title: String,
        items: [AssetHolding]
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            Text(title)
                .font(.headline)

            VStack(spacing: 0) {

                ForEach(items) { asset in

                    assetRow(asset)

                    if asset.id != items.last?.id {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }

    private func assetRow(_ asset: AssetHolding) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName: AssetType(
                    rawValue: asset.symbol.lowercased()
                )?.icon ?? "wallet.pass"
            )
            .font(.title3)
            .foregroundStyle(.blue)
            .frame(width: 36, height: 36)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {

                Text(asset.name)
                    .font(.subheadline.weight(.semibold))

                Text(
                    "\(formatQuantity(asset.quantity)) \(asset.unit)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if let value = viewModel.convertedAmount(
                    quantity: asset.quantity,
                    symbol: asset.symbol,
                    targetCurrency: selectedCurrency
                ) {

                    Text(
                        viewModel.formattedAmount(
                            value,
                            currency: selectedCurrency
                        )
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)

                } else {

                    Text("Güncel değer alınamadı")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                selectedAsset = asset
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .accessibilityLabel("\(asset.name) düzenle")

            Button(role: .destructive) {
                assetToDelete = asset
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityLabel("\(asset.name) sil")
        }
        .padding(.vertical, 8)
    }

    private func deleteAsset() {
        guard let assetToDelete else { return }

        modelContext.delete(assetToDelete)

        do {
            try modelContext.save()
            self.assetToDelete = nil
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func formatQuantity(_ quantity: Decimal) -> String {
        quantity.formatted(
            .number
                .precision(.fractionLength(0...4))
                .locale(Locale(identifier: "tr_TR"))
        )
    }
}
