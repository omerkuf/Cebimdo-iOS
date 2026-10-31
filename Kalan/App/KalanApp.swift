import SwiftUI
import SwiftData

@main
struct KalanApp: App {
    
    @AppStorage("appearance")
    private var appearance = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .font(KalanFont.body)
                .preferredColorScheme(
                    AppAppearance(
                        rawValue: appearance
                    )?.colorScheme
                )
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
