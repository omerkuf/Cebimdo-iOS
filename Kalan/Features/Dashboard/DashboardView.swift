//
//  DashboardView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Binding var selectedTab: AppTab
    @Binding var selectedAddType: Int
    
    @ObservedObject var assetsViewModel: AssetsViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Query private var incomes: [Income]
    @Query private var payments: [Payment]
    @Query private var assetHoldings: [AssetHolding]
    @Query private var incomeChanges: [IncomeAmountChange]
    @Query private var incomeOverrides: [IncomeOccurrenceOverride]

    @Query(sort: \PaymentOccurrence.dueDate)
    private var occurrences: [PaymentOccurrence]

    @State private var selectedOccurrence: PaymentOccurrence?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSettings = false
    
    @State private var showKalanChat = false
    
    @AppStorage("salaryDay")
    private var salaryDay = 15
    
    private var currentSalaryCycle: SalaryCycle? {
        SalaryCycleService.cycle(
            salaryDay: salaryDay
        )
    }

    private let calendar = Calendar.current
    private let trLocale = Locale(identifier: "tr_TR")
    
    private var summaryColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }

        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var currentMonth: Date {
        Date()
    }

    private var monthlyOccurrences: [PaymentOccurrence] {
        guard let interval = calendar.dateInterval(
            of: .month,
            for: currentMonth
        ) else {
            return []
        }

        return occurrences.filter {
            interval.contains($0.dueDate)
        }
    }

    private var monthlyIncome: Decimal {
        DashboardCalculator.monthlyIncome(
            incomes: incomes,
            month: Date(),
            changes: incomeChanges,
            overrides: incomeOverrides
        )
    }

    private var monthlyPaid: Decimal {
        DashboardCalculator.monthlyPaid(
            occurrences: monthlyOccurrences
        )
    }

    private var monthlyUnpaid: Decimal {
        DashboardCalculator.monthlyUnpaid(
            occurrences: monthlyOccurrences
        )
    }

    private var remainingBudget: Decimal {
        DashboardCalculator.remainingBudget(
            income: monthlyIncome,
            occurrences: monthlyOccurrences
        )
    }

    private var upcomingPayments: [PaymentOccurrence] {

        let today = calendar.startOfDay(for: Date())

        guard let endDate = calendar.date(
            byAdding: .day,
            value: 30,
            to: today
        ) else {
            return []
        }

        return occurrences
            .filter {
                !$0.isPaid &&
                calendar.startOfDay(for: $0.dueDate) <= endDate
            }
            .sorted {
                $0.dueDate < $1.dueDate
            }
    }
    
    private var salaryPeriodIncome: Decimal {

        let calendar = Calendar.current

        let start = calendar.startOfDay(for: salaryPeriodStart)
        let end = calendar.startOfDay(for: salaryPeriodEnd)

        guard start < end else {
            return .zero
        }

        var total = Decimal.zero
        var month = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: start
            )
        )!

        while month < end {

            for income in incomes {

                let dates = RecurrenceService.dates(
                    in: month,
                    from: income.startDate,
                    recurrence: RecurrenceType(
                        rawValue: income.recurrence
                    ) ?? .once,
                    endDate: income.endDate
                )

                for date in dates where date >= start && date < end {

                    total += IncomeHistoryService.amount(
                        for: income,
                        on: date,
                        changes: incomeChanges,
                        overrides: incomeOverrides
                    )
                }
            }

            guard let next = calendar.date(
                byAdding: .month,
                value: 1,
                to: month
            ) else {
                break
            }

            month = next
        }

        return total
    }
    
    private var salaryPeriodStart: Date {
        currentSalaryCycle?.startDate
            ?? Calendar.current.startOfDay(for: Date())
    }

    private var salaryPeriodEnd: Date {
        currentSalaryCycle?.endDate
            ?? Calendar.current.startOfDay(for: Date())
    }

    private var daysUntilSalary: Int {
        currentSalaryCycle?.daysRemaining ?? 1
    }

    private var periodOccurrences: [PaymentOccurrence] {
        occurrences.filter {
            $0.dueDate >= salaryPeriodStart &&
            $0.dueDate < salaryPeriodEnd
        }
    }

    private var periodRemainingBudget: Decimal {
        let totalPayments = periodOccurrences.reduce(.zero) {
            $0 + $1.amount
        }

        return salaryPeriodIncome - totalPayments
    }

    private var dailyLimit: Decimal {
        BudgetCalculator.dailyLimit(
            remainingBudget: periodRemainingBudget,
            daysRemaining: daysUntilSalary
        )
    }
    
    private var portfolioTotal: Decimal? {

        guard !assetHoldings.isEmpty else {
            return nil
        }

        let values = assetHoldings.compactMap { asset in
            assetsViewModel.convertedAmount(
                quantity: asset.quantity,
                symbol: asset.symbol,
                targetCurrency: "TRY"
            )
        }

        guard values.count == assetHoldings.count else {
            return nil
        }

        return values.reduce(.zero, +)
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

                    dashboardHeader

                    portfolioCard

                    summaryCards

                    quickActions

                    upcomingPaymentsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 12)
            }
            .background {
                ZStack {
                    DashboardColors.background

                    RadialGradient(
                        colors: [
                            DashboardColors.lightGreen,
                            DashboardColors.background.opacity(0)
                        ],
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 380
                    )
                }
                .ignoresSafeArea()
            }
            .tint(DashboardColors.primaryGreen)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                generatePayments()
            }
            .onChange(of: payments.count) { _, _ in
                generatePayments()
            }
            .sheet(item: $selectedOccurrence) { occurrence in
                PaymentOccurrenceEditView(
                    occurrence: occurrence
                )
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showKalanChat) {
                NavigationStack {
                    KalanChatView(
                        assetsViewModel: assetsViewModel
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Kapat") {
                                showKalanChat = false
                            }
                        }
                    }
                }
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "İşlem tamamlanamadı.")
            }
        }
    }
    
    private var dashboardHeader: some View {
        HStack(spacing: 12) {

            Image("KalanMark")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("KALAN")
                    .font(.custom("AvenirNext-Bold", size: 30))
                    .foregroundStyle(.primary)

                Text("Finansın kontrol altında")
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            Button {
                showKalanChat = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        Color(red: 15 / 255.0,
                              green: 122 / 255.0,
                              blue: 67 / 255.0)
                    )
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                Color(red: 230 / 255.0,
                                      green: 246 / 255.0,
                                      blue: 237 / 255.0)
                            )
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("KALAN Chat")

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.9))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ayarlar")
        }
        .frame(maxWidth: .infinity)
    }

    private var portfolioCard: some View {

        Button {
            selectedTab = .assets
        } label: {

            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("Portföyüm")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.secondary)

                if assetHoldings.isEmpty {

                    Text("Henüz varlık eklenmedi")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Varlık eklemek için dokunun")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                } else if let portfolioTotal {

                    Text(
                        assetsViewModel.formattedAmount(
                            portfolioTotal,
                            currency: "TRY"
                        )
                    )
                    .font(
                        .custom(
                            "AvenirNext-Bold",
                            size: 30,
                            relativeTo: .title
                        )
                    )
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                    Text("Toplam tahmini portföy değerim")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let updatedAt = assetsViewModel.metals?.updatedAt,
                       let date = parseMarketDate(updatedAt) {

                        let formattedDate = date.formatted(
                            .dateTime
                                .day()
                                .month(.wide)
                                .hour()
                                .minute()
                                .locale(trLocale)
                        )

                        Text("Maden fiyatı: \(formattedDate)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                } else if assetsViewModel.isLoading ||
                            assetsViewModel.isLoadingMetals {

                    HStack(spacing: 10) {
                        ProgressView()

                        Text("Portföy hesaplanıyor...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                } else {

                    Text("Portföy değeri alınamadı")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Güncel fiyatları kontrol etmek için dokunun")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "wallet.pass")
                        .foregroundStyle(DashboardColors.primaryGreen)

                    Text("\(assetHoldings.count) varlık kaydı")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .shadow(
                color: DashboardColors.primaryGreen.opacity(0.06),
                radius: 12,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(.plain)
    }

    private var summaryCards: some View {
        LazyVGrid(
            columns: summaryColumns,
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
                amount: monthlyPaid,
                icon: "arrow.up.right",
                color: .red,
                subtitle: "Ödenmiş ödemeler"
            )

            SummaryCard(
                title: "Kalan Bütçem",
                amount: remainingBudget,
                icon: "wallet.pass",
                color: DashboardColors.primaryGreen,
                subtitle: "Ödemeler düşüldü"
            )

            SummaryCard(
                title: "Günlük Limitim",
                amount: dailyLimit,
                icon: "calendar",
                color: .green,
                subtitle: "Tahmini · sonraki maaşa kadar"
            )
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {

            Button {
                selectedAddType = 0
                selectedTab = .add
            } label: {
                Label("Gelir Ekle", systemImage: "plus")
                    .font(KalanFont.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        Capsule()
                            .fill(DashboardColors.primaryGreen)
                    )
            }
            .buttonStyle(.plain)

            Button {
                selectedAddType = 1
                selectedTab = .add
            } label: {
                Label(
                    "Ödeme Ekle",
                    systemImage: "calendar.badge.plus"
                )
                .font(KalanFont.button)
                .foregroundStyle(DashboardColors.primaryGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    Capsule()
                        .fill(DashboardColors.lightGreen)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var upcomingPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Gecikmiş ve Yaklaşan Ödemeler")
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
                    description: Text(
                        "Bu ay için bekleyen ödeme bulunmuyor."
                    )
                )

            } else {

                ForEach(upcomingPayments) { occurrence in

                    paymentRow(occurrence)

                    if occurrence.id != upcomingPayments.last?.id {
                        Divider()
                    }
                }
            }

            Divider()

            HStack {
                Text("Toplam Bekleyen")
                    .font(.subheadline)

                Spacer()

                Text(
                    formatCurrency(
                        upcomingPayments.reduce(.zero) {
                            $0 + $1.amount
                        }
                    )
                )
                .font(.subheadline.weight(.bold))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .shadow(
            color: DashboardColors.primaryGreen.opacity(0.04),
            radius: 10,
            x: 0,
            y: 4
        )
    }

    private func paymentRow(
        _ occurrence: PaymentOccurrence
    ) -> some View {

        HStack(spacing: 10) {

            Image(systemName: "doc.text")
                .foregroundStyle(DashboardColors.primaryGreen)
                .frame(width: 32, height: 32)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {

                Text(occurrence.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(
                    occurrence.dueDate.formatted(
                        .dateTime.day().month(.wide)
                            .locale(trLocale)
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                // Ödeme tarihi geçmişse gecikmiş uyarısı göster
                if calendar.startOfDay(for: occurrence.dueDate)
                    < calendar.startOfDay(for: Date()) && !occurrence.isPaid {

                    Text("Gecikmiş")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                }

                Text(formatCurrency(occurrence.amount))
                    .font(.caption.weight(.semibold))
            }

            Spacer(minLength: 4)

            Button {
                selectedOccurrence = occurrence
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .accessibilityLabel("Ödemeyi düzenle")

            Button {
                togglePayment(occurrence)
            } label: {
                Text("Ödendi")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(DashboardColors.primaryGreen)
        }
        .padding(.vertical, 6)
    }

    private func generatePayments() {
        do {
            let today = Date()

            guard
                let startMonth = calendar.dateInterval(
                    of: .month,
                    for: salaryPeriodStart
                )?.start,
                let lastMonth = calendar.dateInterval(
                    of: .month,
                    for: calendar.date(
                        byAdding: .day,
                        value: 30,
                        to: today
                    ) ?? today
                )?.start
            else {
                return
            }

            var month = startMonth

            while month <= lastMonth {

                try PaymentOccurrenceService.generateOccurrences(
                    for: month,
                    context: modelContext
                )

                guard let next = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: month
                ) else {
                    break
                }

                month = next
            }

        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func togglePayment(
        _ occurrence: PaymentOccurrence
    ) {
        occurrence.isPaid = true
        occurrence.paidDate = Date()

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func formatCurrency(
        _ amount: Decimal
    ) -> String {
        amount.formatted(
            .currency(code: "TRY")
                .locale(trLocale)
        )
    }
}

private enum DashboardColors {
    static let background = Color(
        red: 240 / 255.0,
        green: 248 / 255.0,
        blue: 245 / 255.0
    )

    static let primaryGreen = Color(
        red: 15 / 255.0,
        green: 122 / 255.0,
        blue: 67 / 255.0
    )

    static let lightGreen = Color(
        red: 230 / 255.0,
        green: 246 / 255.0,
        blue: 237 / 255.0
    )

    static let accentGreen = Color(
        red: 34 / 255.0,
        green: 197 / 255.0,
        blue: 94 / 255.0
    )
}
