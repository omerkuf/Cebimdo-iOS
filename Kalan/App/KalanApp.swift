import SwiftUI
import SwiftData

@main
struct KalanApp: App {

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            Income.self,
            Payment.self,
            PaymentOccurrence.self,
            AssetHolding.self,
            IncomeAmountChange.self,
            IncomeOccurrenceOverride.self
        ])
    }
}
