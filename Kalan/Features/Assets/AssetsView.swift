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
                        VStack(spacing: 0) {
                            ForEach(assets) { asset in
                                assetRow(asset)

                                if asset.id != assets.last?.id {
                                    Divider()
                                        .padding(.leading, 54)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                    }

                    addAssetButton
                }
                .padding(16)
            }
            .background(AssetsColors.background.ignoresSafeArea())
            .tint(AssetsColors.primaryGreen)
            .navigationTitle("Varlıklarım")
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
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Toplam Varlık Değerim")
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.85))
            }

            if let portfolioTotal {
                Text(
                    viewModel.formattedAmount(
                        portfolioTotal,
                        currency: selectedCurrency
                    )
                )
                .font(.custom("AvenirNext-Bold", size: 29))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

                Text("Güncel piyasa değerleri ile")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                Text(
                    assets.isEmpty
                        ? "Henüz varlık eklenmedi"
                        : "Portföy hesaplanıyor..."
                )
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(.white)
            }

            // TRY, USD ve EUR seçimi korunuyor.
            Picker(
                "Görüntüleme Para Birimi",
                selection: $selectedCurrency
            ) {
                ForEach(supportedCurrencies, id: \.self) { currency in
                    Text(currency).tag(currency)
                }
            }
            .pickerStyle(.segmented)
            .tint(AssetsColors.primaryGreen)

            if viewModel.isLoading || viewModel.isLoadingMetals {
                ProgressView("Fiyatlar güncelleniyor...")
                    .font(.caption)
                    .tint(.white)
                    .foregroundStyle(.white)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                Image(systemName: "wallet.pass")

                Text("\(assets.count) varlık kaydı")

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
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Fiyatları yenile")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.9))

            if let lastUpdated = viewModel.lastUpdated {
                Text("Kur tarihi: \(lastUpdated)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }

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
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.02, green: 0.35, blue: 0.20),
                            AssetsColors.primaryGreen,
                            Color(red: 0.02, green: 0.56, blue: 0.29)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    
    private var addAssetButton: some View {
        Button {
            showAddAsset = true
        } label: {
            Label("Varlık Ekle", systemImage: "plus")
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(AssetsColors.primaryGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(AssetsColors.lightGreen)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Yeni varlık ekle")
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

        HStack(alignment: .center, spacing: 10) {

            // Şimdilik SF Symbol kullanıyoruz.
            // Sonrasında altın, gümüş ve döviz görsellerini Assets'e ekleyeceğiz.
            Image(systemName: assetIcon(for: asset.symbol))
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(assetIconColor(for: asset.symbol))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AssetsColors.lightGreen)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(formatQuantity(asset.quantity)) \(asset.unit)")
                    .font(.custom("AvenirNext-Regular", size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {

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
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                } else {
                    Text("Değer alınamadı")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {

                    Button {
                        selectedAsset = asset
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.secondary)
                            .background(
                                Circle()
                                    .fill(Color(.tertiarySystemGroupedBackground))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(asset.name) düzenle")

                    Button(role: .destructive) {
                        assetToDelete = asset
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.red)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(asset.name) sil")
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    
    private func assetIcon(for symbol: String) -> String {
        switch symbol.uppercased() {
        case "XAU":
            return "circle.hexagongrid.fill"
        case "XAG":
            return "square.stack.3d.up.fill"
        case "USD", "EUR", "GBP", "CHF":
            return "dollarsign.circle.fill"
        default:
            return "wallet.pass.fill"
        }
    }

    private func assetIconColor(for symbol: String) -> Color {
        switch symbol.uppercased() {
        case "XAU":
            return Color(red: 0.88, green: 0.62, blue: 0.06)
        case "XAG":
            return .gray
        default:
            return AssetsColors.primaryGreen
        }
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
