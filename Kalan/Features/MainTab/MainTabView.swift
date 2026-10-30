//
//  MainTabView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home
    case transactions
    case add
    case assets
    case analytics
}

struct MainTabView: View {
    
    @Query private var assetHoldings: [AssetHolding]

    @State private var selectedTab: AppTab = .home
    @State private var selectedAddType = 0
    
    @StateObject private var assetsViewModel = AssetsViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {

            DashboardView(
                selectedTab: $selectedTab,
                selectedAddType: $selectedAddType,
                assetsViewModel: assetsViewModel
            )
            .tabItem {
                Label("Ana Sayfa", systemImage: "house")
            }
            .tag(AppTab.home)

            TransactionsView()
                .tabItem {
                    Label("İşlemler", systemImage: "arrow.left.arrow.right")
                }
                .tag(AppTab.transactions)

            AddTransactionView(
                selectedType: $selectedAddType
            )
            .tabItem {
                Label("Ekle", systemImage: "plus.circle")
            }
            .tag(AppTab.add)

            AssetsView(viewModel: assetsViewModel)
                .tabItem {
                    Label("Varlıklarım", systemImage: "wallet.pass")
                }
                .tag(AppTab.assets)

            AnalyticsView()
                .tabItem {
                    Label("Analiz", systemImage: "chart.pie")
                }
                .tag(AppTab.analytics)
        }
        .task(id: assetHoldings.map(\.symbol).sorted().joined(separator: ",")) {
            await assetsViewModel.refreshIfNeeded(
                needsMetals: assetHoldings.contains {
                    $0.symbol == "XAU" || $0.symbol == "XAG"
                }
            )
        }
    }
}
