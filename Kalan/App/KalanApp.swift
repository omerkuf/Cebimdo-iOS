import SwiftUI
import SwiftData

@main
struct KalanApp: App {
    
    @AppStorage("appearance")
    private var appearance = AppAppearance.system.rawValue
    
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()

                if isShowingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .font(KalanFont.body)
            .preferredColorScheme(.light)
            .task {
                guard isShowingSplash else { return }

                try? await Task.sleep(for: .seconds(1.5))

                withAnimation(.easeOut(duration: 0.25)) {
                    isShowingSplash = false
                }
            }
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
