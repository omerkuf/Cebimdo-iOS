//
//  DashboardView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI

struct DashboardView: View {

    @Binding var selectedTab: AppTab

    @State private var payments = DemoPayment.samples
    @State private var selectedPayment: DemoPayment?

    // Şimdilik örnek gelir ve portföy değerleri
    private let monthlyIncome: Decimal = 85000
    private let portfolioValue: Decimal = 1250000

    private var paidTotal: Decimal {
        payments
            .filter { $0.isPaid }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var unpaidTotal: Decimal {
        payments
            .filter { !$0.isPaid }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var remainingBudget: Decimal {
        monthlyIncome - paidTotal - unpaidTotal
    }

    private var dailyLimit: Decimal {
        max(Decimal.zero, remainingBudget) / 15
    }

    private var upcomingPayments: [DemoPayment] {
        payments
            .filter { !$0.isPaid }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    portfolioCard

                    summaryCards

                    quickActions

                    upcomingPaymentsSection
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KALAN")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Ayarlar ekranını daha sonra bağlayacağız
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .disabled(true)
                }
            }
            .sheet(item: $selectedPayment) { payment in
                EditPaymentView(payment: payment) { updated in
                    updatePayment(updated)
                }
            }
        }
    }

    private var portfolioCard: some View {
        Button {
            selectedTab = .assets
        } label: {
            VStack(alignment: .leading, spacing: 10) {

                HStack {
                    Text("Portföyüm")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.secondary)

                Text(formatCurrency(portfolioValue))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("Varlıklarımın toplam TL karşılığı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            SummaryCard(
                title: "Aylık Gelirim",
                amount: monthlyIncome,
                icon: "arrow.down.left",
                color: .green,
                subtitle: "Maaş + ek gelir"
            )

            SummaryCard(
                title: "Aylık Harcamam",
                amount: paidTotal,
                icon: "arrow.up.right",
                color: .red,
                subtitle: "Ödenmiş ödemeler"
            )

            SummaryCard(
                title: "Kalan Bütçem",
                amount: remainingBudget,
                icon: "wallet.pass",
                color: .blue,
                subtitle: "Bekleyen giderler düşüldü"
            )

            SummaryCard(
                title: "Günlük Limitim",
                amount: dailyLimit,
                icon: "calendar",
                color: .green,
                subtitle: "Örnek: 15 gün"
            )
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {

            Button {
                selectedTab = .add
            } label: {
                Label("Gelir Ekle", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                selectedTab = .add
            } label: {
                Label("Ödeme Ekle", systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Yaklaşan Ödemeler")
                    .font(.headline)

                Spacer()

                Button("Tümünü Gör") {
                    selectedTab = .transactions
                }
                .font(.caption)
            }

            if upcomingPayments.isEmpty {
                ContentUnavailableView(
                    "Bekleyen ödemeniz yok",
                    systemImage: "checkmark.circle",
                    description: Text("Tüm ödemeler tamamlandı.")
                )
            } else {
                ForEach(upcomingPayments) { payment in

                    PaymentRow(
                        payment: payment,
                        onEdit: {
                            selectedPayment = payment
                        },
                        onTogglePaid: {
                            togglePayment(payment)
                        }
                    )

                    if payment.id != upcomingPayments.last?.id {
                        Divider()
                    }
                }
            }

            Divider()

            HStack {
                Text("Toplam Bekleyen")
                    .font(.subheadline)

                Spacer()

                Text(formatCurrency(unpaidTotal))
                    .font(.subheadline.weight(.bold))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func togglePayment(_ payment: DemoPayment) {
        guard let index = payments.firstIndex(
            where: { $0.id == payment.id }
        ) else {
            return
        }

        payments[index].isPaid.toggle()
    }

    private func updatePayment(_ payment: DemoPayment) {
        guard let index = payments.firstIndex(
            where: { $0.id == payment.id }
        ) else {
            return
        }

        payments[index] = payment
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: "TRY")
                .locale(Locale(identifier: "tr_TR"))
        )
    }
}
