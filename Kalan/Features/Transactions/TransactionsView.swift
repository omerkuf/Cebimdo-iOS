//
//  TransactionsView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct TransactionsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Income.startDate, order: .reverse)
    private var incomes: [Income]

    @Query private var payments: [Payment]
    @Query private var incomeChanges: [IncomeAmountChange]
    @Query private var incomeOverrides: [IncomeOccurrenceOverride]

    @Query(sort: \PaymentOccurrence.dueDate)
    private var occurrences: [PaymentOccurrence]

    @State private var selectedType = 0
    @State private var paymentFilter = 0
    @State private var selectedMonth = Date()
    @State private var selectedOccurrence: PaymentOccurrence?
    
    @State private var selectedIncomeEdit: SelectedIncomeEdit?

    @State private var errorMessage: String?
    @State private var showError = false

    @State private var incomeToDelete: Income?
    @State private var paymentToDelete: Payment?
    @State private var showDeleteIncome = false
    @State private var showDeletePayment = false

    private let calendar = Calendar.current
    private let trLocale = Locale(identifier: "tr_TR")

    private var monthInterval: DateInterval? {
        calendar.dateInterval(
            of: .month,
            for: selectedMonth
        )
    }

    private var monthlyOccurrences: [PaymentOccurrence] {
        guard let interval = monthInterval else {
            return []
        }

        return occurrences.filter {
            interval.contains($0.dueDate)
        }
    }

    private var filteredOccurrences: [PaymentOccurrence] {
        monthlyOccurrences
            .filter {
                paymentFilter == 0 ? !$0.isPaid : $0.isPaid
            }
            .sorted {
                $0.dueDate < $1.dueDate
            }
    }

    private var totalAmount: Decimal {
        filteredOccurrences.reduce(.zero) {
            $0 + $1.amount
        }
    }
    
    // Seçilen ayın gelir kayıtları
    private var monthlyIncomeItems: [IncomeDisplayItem] {
        incomes.flatMap { income in
            RecurrenceService.dates(
                in: selectedMonth,
                from: income.startDate,
                recurrence: RecurrenceType(
                    rawValue: income.recurrence
                ) ?? .once,
                endDate: income.endDate
            ).map { date in
                IncomeDisplayItem(
                    id: "\(income.id.uuidString)-\(date.timeIntervalSince1970)",
                    name: income.name,
                    amount: IncomeHistoryService.amount(
                        for: income,
                        on: date,
                        changes: incomeChanges,
                        overrides: incomeOverrides
                    ),
                    category: income.category,
                    date: date,
                    sourceID: income.id
                )
            }
        }
    }

    // Gelirler ve ödemeler tek listede
    private var transactionItems: [TransactionListItem] {

        let incomeItems = monthlyIncomeItems.map {
            TransactionListItem.income($0)
        }

        let paymentItems = monthlyOccurrences
            .filter {
                selectedType != 2 ||
                (paymentFilter == 0 ? !$0.isPaid : $0.isPaid)
            }
            .map {
                TransactionListItem.payment($0)
            }

        let items: [TransactionListItem]

        switch selectedType {
        case 1:
            items = incomeItems
        case 2:
            items = paymentItems
        default:
            items = incomeItems + paymentItems
        }

        return items.sorted { $0.date > $1.date }
    }

    private var visibleTotal: Decimal {
        switch selectedType {
        case 1:
            return monthlyIncomeItems.reduce(.zero) {
                $0 + $1.amount
            }
        case 2:
            return transactionItems.reduce(.zero) {
                $0 + $1.amount
            }
        default:
            let incomeTotal = monthlyIncomeItems.reduce(.zero) {
                $0 + $1.amount
            }
            let paymentTotal = monthlyOccurrences.reduce(.zero) {
                $0 + $1.amount
            }
            return incomeTotal - paymentTotal
        }
    }

    
    private func deleteIncome() {

        guard let incomeToDelete else {
            return
        }

        // Gelire ait ileriye dönük tutar değişikliklerini sil
        let relatedChanges = incomeChanges.filter {
            $0.incomeID == incomeToDelete.id
        }

        relatedChanges.forEach {
            modelContext.delete($0)
        }

        // Gelire ait tek dönemlik özel tutarları sil
        let relatedOverrides = incomeOverrides.filter {
            $0.incomeID == incomeToDelete.id
        }

        relatedOverrides.forEach {
            modelContext.delete($0)
        }

        // Gelir kaydını sil
        modelContext.delete(incomeToDelete)

        do {
            try modelContext.save()
            self.incomeToDelete = nil
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func deletePayment() {
        guard let paymentToDelete else { return }

        let relatedOccurrences = occurrences.filter {
            $0.paymentID == paymentToDelete.id
        }

        relatedOccurrences.forEach {
            modelContext.delete($0)
        }

        modelContext.delete(paymentToDelete)

        do {
            try modelContext.save()
            self.paymentToDelete = nil
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    var body: some View {
        NavigationStack {
            
            ScrollView {
                VStack(spacing: 18) {

                    Picker("İşlem Türü", selection: $selectedType) {
                        Text("Tümü").tag(0)
                        Text("Gelirler").tag(1)
                        Text("Ödemeler").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .tint(TransactionColors.primary)
                    .padding(.horizontal, 16)

                    monthSelector

                    transactionContent
                }
                .padding(.top, 16)
            }
            .background(
                TransactionColors.background
                    .ignoresSafeArea()
            )
            .tint(TransactionColors.primary)
            .navigationTitle("İşlemlerim")
            .onAppear {
                generatePayments()
            }
            .onChange(of: selectedMonth) { _, _ in
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
            .sheet(item: $selectedIncomeEdit) { selected in
                IncomeEditView(
                    income: selected.income,
                    selectedDate: selected.date
                )
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "İşlem tamamlanamadı.")
            }
            .alert(
                "Geliri Sil",
                isPresented: $showDeleteIncome
            ) {
                Button("Vazgeç", role: .cancel) {
                    incomeToDelete = nil
                }

                Button("Sil", role: .destructive) {
                    deleteIncome()
                }
            } message: {
                Text(
                    "Bu gelir tanımı silinecek. " +
                    "Tekrarlayan gelirlerin bütün dönemleri etkilenecek."
                )
            }
            .alert(
                "Ödeme Serisini Sil",
                isPresented: $showDeletePayment
            ) {
                Button("Vazgeç", role: .cancel) {
                    paymentToDelete = nil
                }

                Button("Sil", role: .destructive) {
                    deletePayment()
                }
            } message: {
                Text(
                    "Bu ödeme ve ona bağlı bütün dönem kayıtları " +
                    "kalıcı olarak silinecek."
                )
            }
        }
    }
        
    private var transactionContent: some View {
        VStack(spacing: 16) {

            // Ödemeler sekmesinde eski durum filtresi korunuyor.
            if selectedType == 2 {
                Picker("Ödeme Durumu", selection: $paymentFilter) {
                    Text("Ödenmemiş").tag(0)
                    Text("Ödenmiş").tag(1)
                }
                .pickerStyle(.segmented)
                .tint(TransactionColors.primary)
            }

            HStack {
                Text("Aylık Net")
                    .font(.custom("AvenirNext-DemiBold", size: 16))

                Spacer()

                Text(formatCurrency(visibleTotal))
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(
                        selectedType == 0
                            ? TransactionColors.primary
                            : TransactionColors.mainText
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if transactionItems.isEmpty {
                ContentUnavailableView(
                    "İşlem Bulunamadı",
                    systemImage: "tray",
                    description: Text(
                        "Seçilen aya ve filtreye ait işlem bulunmuyor."
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(transactionItems) { item in
                        transactionRow(item)

                        if item.id != transactionItems.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .shadow(
                    color: TransactionColors.primary.opacity(0.05),
                    radius: 10,
                    x: 0,
                    y: 4
                )
            }

            HStack {
                Text(
                    selectedType == 0
                        ? "Net Tutar"
                        : selectedType == 1
                            ? "Toplam Gelir"
                            : paymentFilter == 0
                                ? "Toplam Bekleyen"
                                : "Toplam Ödenen"
                )
                .font(.custom("AvenirNext-DemiBold", size: 14))

                Spacer()

                Text(formatCurrency(visibleTotal))
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    
    @ViewBuilder
    private func transactionRow(
        _ item: TransactionListItem
    ) -> some View {

        HStack(alignment: .center, spacing: 10) {

            Image(systemName: transactionIcon(item))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(transactionIconColor(item))
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(transactionIconColor(item).opacity(0.10))
                )

            VStack(alignment: .leading, spacing: 4) {
                switch item {
                case .income(let income):
                    Text(income.name)
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .lineLimit(2)

                case .payment(let occurrence):
                    Text(occurrence.name)
                        .font(.custom("AvenirNext-DemiBold", size: 14))
                        .lineLimit(2)
                }

                Text(
                    item.date.formatted(
                        .dateTime.day().month(.wide)
                            .locale(trLocale)
                    )
                )
                .font(.custom("AvenirNext-Regular", size: 12))
                .foregroundStyle(.secondary)

                if case .payment(let occurrence) = item,
                   !occurrence.isPaid,
                   calendar.startOfDay(for: occurrence.dueDate)
                        < calendar.startOfDay(for: Date()) {

                    Text("Gecikmiş")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 7) {

                Text(transactionAmountText(item))
                    .font(.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundStyle(
                        transactionIsIncome(item)
                            ? TransactionColors.primary
                            : TransactionColors.mainText
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                HStack(spacing: 8) {

                    Button {
                        switch item {
                        case .income(let income):

                            print("MAAŞ KALEM BUTONUNA BASILDI")
                            print("Income ID:", income.sourceID)

                            guard let source = incomes.first(where: {
                                $0.id == income.sourceID
                            }) else {
                                errorMessage = "Düzenlenecek gelir kaydı bulunamadı."
                                showError = true
                                return
                            }

                            selectedIncomeEdit = SelectedIncomeEdit(
                                income: source,
                                date: income.date
                            )

                            print("IncomeEditView için seçim oluşturuldu")
                        case .payment(let occurrence):
                            selectedOccurrence = occurrence
                        }
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("İşlemi düzenle")

                    Button {
                        switch item {
                        case .income(let income):
                            incomeToDelete = incomes.first {
                                $0.id == income.sourceID
                            }
                            showDeleteIncome = incomeToDelete != nil

                        case .payment(let occurrence):
                            paymentToDelete = payments.first {
                                $0.id == occurrence.paymentID
                            }
                            showDeletePayment = paymentToDelete != nil
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("İşlemi sil")

                    if case .payment(let occurrence) = item {
                        Button {
                            togglePaid(occurrence)
                        } label: {
                            Image(
                                systemName: occurrence.isPaid
                                    ? "arrow.uturn.backward.circle"
                                    : "checkmark.circle"
                            )
                            .foregroundStyle(
                                occurrence.isPaid
                                    ? Color.secondary
                                    : TransactionColors.primary
                            )
                            .frame(width: 32, height: 32)
                        }
                        .accessibilityLabel(
                            occurrence.isPaid
                                ? "Ödemeyi geri al"
                                : "Ödendi olarak işaretle"
                        )
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
    }
    
    
    private func transactionIsIncome(
        _ item: TransactionListItem
    ) -> Bool {
        if case .income = item {
            return true
        }
        return false
    }

    private func transactionAmountText(
        _ item: TransactionListItem
    ) -> String {
        let prefix = transactionIsIncome(item) ? "+" : "−"
        return prefix + formatCurrency(item.amount)
    }

    private func transactionIcon(
        _ item: TransactionListItem
    ) -> String {
        switch item {
        case .income:
            return "briefcase"

        case .payment(let occurrence):
            let name = occurrence.name.lowercased()

            if name.contains("kira") {
                return "house"
            } else if name.contains("market") {
                return "cart"
            } else if name.contains("elektrik") {
                return "bolt"
            } else if name.contains("internet") {
                return "wifi"
            }
            return "doc.text"
        }
    }

    private func transactionIconColor(
        _ item: TransactionListItem
    ) -> Color {
        switch item {
        case .income:
            return TransactionColors.primary

        case .payment(let occurrence):
            let name = occurrence.name.lowercased()

            if name.contains("elektrik") {
                return .orange
            } else if name.contains("internet") {
                return .purple
            }
            return .red
        }
    }




    private var monthSelector: some View {
        HStack {

            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 40)
            }

            Spacer()

            Text(
                selectedMonth.formatted(
                    .dateTime.month(.wide).year()
                        .locale(trLocale)
                )
            )
            .font(.headline)

            Spacer()

            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 40)
            }
        }
        .padding(.horizontal)
        .tint(TransactionColors.primary)
    }

    @ViewBuilder
    private var incomeContent: some View {

        let monthlyIncomes = incomes.flatMap { income in

            RecurrenceService.dates(
                in: selectedMonth,
                from: income.startDate,
                recurrence: RecurrenceType(
                    rawValue: income.recurrence
                ) ?? .once,
                endDate: income.endDate
            ).map { date in
                IncomeDisplayItem(
                    id: "\(income.id.uuidString)-\(date.timeIntervalSince1970)",
                    name: income.name,
                    amount: IncomeHistoryService.amount(
                        for: income,
                        on: date,
                        changes: incomeChanges,
                        overrides: incomeOverrides
                    ),
                    category: income.category,
                    date: date,
                    sourceID: income.id
                )
            }
        }
        .sorted { $0.date < $1.date }

        List {
            if monthlyIncomes.isEmpty {

                ContentUnavailableView(
                    "Gelir Bulunamadı",
                    systemImage: "tray",
                    description: Text(
                        "Bu aya ait gelir kaydı bulunmuyor."
                    )
                )

            } else {

                ForEach(monthlyIncomes) { income in

                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.left")
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(income.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text(income.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                income.date.formatted(
                                    .dateTime.day().month(.wide)
                                        .locale(trLocale)
                                )
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 4)

                        Text(formatCurrency(income.amount))
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .layoutPriority(1)

                        // Geliri düzenle
                        Button {
                            if let sourceIncome = incomes.first(where: {
                                $0.id == income.sourceID
                            }) {
                                selectedIncomeEdit = SelectedIncomeEdit(
                                    income: sourceIncome,
                                    date: income.date
                                )
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .frame(width: 30, height: 30)
                        }

                        // Geliri sil
                        Button {
                            incomeToDelete = incomes.first {
                                $0.id == income.sourceID
                            }

                            showDeleteIncome = incomeToDelete != nil
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .frame(width: 20, height: 24)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .accessibilityLabel("Geliri sil")
                    }
                    .padding(.vertical, 5)
                }

                Section {
                    totalRow(
                        title: "Toplam Gelir",
                        amount: monthlyIncomes.reduce(.zero) {
                            $0 + $1.amount
                        }
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var paymentContent: some View {
        VStack(spacing: 0) {

            Picker("Ödeme Durumu", selection: $paymentFilter) {
                Text("Ödenmemiş").tag(0)
                Text("Ödenmiş").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {

                if filteredOccurrences.isEmpty {

                    ContentUnavailableView(
                        "Ödeme Bulunamadı",
                        systemImage: "checkmark.circle",
                        description: Text(
                            "Bu bölümde ödeme bulunmuyor."
                        )
                    )

                } else {

                    ForEach(filteredOccurrences) { occurrence in

                        HStack(spacing: 6) {

                            VStack(alignment: .leading, spacing: 5) {
                                Text(occurrence.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .layoutPriority(1)

                                Text(
                                    occurrence.dueDate.formatted(
                                        .dateTime.day().month(.wide)
                                            .locale(trLocale)
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                // Ödenmemiş ve tarihi geçmiş ödemeleri göster
                                if calendar.startOfDay(for: occurrence.dueDate)
                                    < calendar.startOfDay(for: Date()) && !occurrence.isPaid {

                                    Text("Gecikmiş")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.red)
                                }

                                Text(formatCurrency(occurrence.amount))
                                    .font(.caption.weight(.medium))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

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
                            
                            // Ödeme serisini sil
                            Button {
                                paymentToDelete = payments.first {
                                    $0.id == occurrence.paymentID
                                }

                                showDeletePayment = paymentToDelete != nil
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .accessibilityLabel("Ödeme serisini sil")

                            Button {
                                togglePaid(occurrence)
                            } label: {
                                Text(
                                    occurrence.isPaid
                                        ? "Geri Al"
                                        : "Ödendi"
                                )
                                .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(occurrence.isPaid ? .gray : .blue)
                        }
                        .padding(.vertical, 6)
                    }

                    Section {
                        totalRow(
                            title: paymentFilter == 0
                                ? "Toplam Bekleyen"
                                : "Toplam Ödenen",
                            amount: totalAmount
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func totalRow(
        title: String,
        amount: Decimal
    ) -> some View {

        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text(formatCurrency(amount))
                .font(.subheadline.weight(.bold))
        }
    }

    private func changeMonth(_ value: Int) {
        guard let next = calendar.date(
            byAdding: .month,
            value: value,
            to: selectedMonth
        ) else {
            return
        }

        selectedMonth = next
    }

    private func generatePayments() {
        do {
            try PaymentOccurrenceService.generateOccurrences(
                for: selectedMonth,
                context: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func togglePaid(_ occurrence: PaymentOccurrence) {

        occurrence.isPaid.toggle()

        occurrence.paidDate = occurrence.isPaid
            ? Date()
            : nil

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: "TRY")
                .locale(trLocale)
        )
    }
}

private struct IncomeDisplayItem: Identifiable {

    let id: String
    let name: String
    let amount: Decimal
    let category: String
    let date: Date
    let sourceID: UUID
}

private struct SelectedIncomeEdit: Identifiable {
    let id = UUID()
    let income: Income
    let date: Date
}

private enum TransactionListItem: Identifiable {

    case income(IncomeDisplayItem)
    case payment(PaymentOccurrence)

    var id: String {
        switch self {
        case .income(let income):
            return "income-\(income.id)"
        case .payment(let payment):
            return "payment-\(payment.id)"
        }
    }

    var date: Date {
        switch self {
        case .income(let income):
            return income.date
        case .payment(let payment):
            return payment.dueDate
        }
    }

    var amount: Decimal {
        switch self {
        case .income(let income):
            return income.amount
        case .payment(let payment):
            return payment.amount
        }
    }
}

