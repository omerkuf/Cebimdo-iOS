//
//  MainTabView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case transactions
    case add
    case assets
    case analytics
}

struct MainTabView: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {

            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }
                .tag(AppTab.home)

            TransactionsView()
                .tabItem {
                    Label("İşlemler", systemImage: "arrow.left.arrow.right")
                }
                .tag(AppTab.transactions)

            AddTransactionView()
                .tabItem {
                    Label("Ekle", systemImage: "plus.circle")
                }
                .tag(AppTab.add)

            AssetsView()
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
    }
}
