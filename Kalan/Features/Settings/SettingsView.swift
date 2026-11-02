//
//  SettingsView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("salaryDay")
    private var salaryDay = 15

    @AppStorage("preferredCurrency")
    private var preferredCurrency = "TRY"

    @AppStorage("appearance")
    private var appearance = "system"
    
    @Environment(\.modelContext) private var modelContext

    @State private var showResetConfirmation = false
    @State private var showResetError = false
    @State private var resetErrorMessage = ""
    
    @MainActor
    private func resetAllData() {

        do {
            try AppDataResetService.reset(
                context: modelContext
            )

            print("KALAN: Tüm SwiftData kayıtları silindi.")

        } catch {
            modelContext.rollback()

            resetErrorMessage = error.localizedDescription
            showResetError = true
        }
    }

    var body: some View {
        NavigationStack {
            Form {

                Section {
                    Picker("Maaş Günüm", selection: $salaryDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("Her ayın \(day)'i")
                                .tag(day)
                        }
                    }
                } header: {
                    Text("Maaş Bilgileri")
                } footer: {
                    Text(
                        "Seçtiğiniz gün ilgili ayda yoksa " +
                        "ayın son günü kullanılacak."
                    )
                }

                Section("Para Birimi") {
                    Picker(
                        "Ana Para Birimim",
                        selection: $preferredCurrency
                    ) {
                        Text("Türk Lirası (TRY)").tag("TRY")
                        Text("Amerikan Doları (USD)").tag("USD")
                        Text("Euro (EUR)").tag("EUR")
                    }
                }

                Section("Görünüm") {
                    Picker("Tema", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.title)
                                .tag(option.rawValue)
                        }
                    }
                }

                Section("Uygulama") {
                    LabeledContent("Uygulama", value: "KALAN")
                    LabeledContent("Sürüm", value: "1.0")
                }
                
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label(
                            "Tüm Verileri Sıfırla",
                            systemImage: "trash"
                        )
                        .foregroundStyle(.red)
                    }
                } header: {
                    Text("Geliştirici Araçları")
                } footer: {
                    Text(
                        "Test amacıyla tüm gelir, ödeme ve varlık kayıtlarını siler. Bu işlem geri alınamaz."
                    )
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Tüm veriler silinsin mi?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Tüm Verileri Kalıcı Olarak Sil", role: .destructive) {
                    resetAllData()
                }

                Button("Vazgeç", role: .cancel) {}

            } message: {
                Text(
                    "Gelirlerin, ödemelerin, ödeme geçmişin ve varlıkların kalıcı olarak silinecek. Bu işlem geri alınamaz."
                )
            }
            .alert("Sıfırlama Başarısız", isPresented: $showResetError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(resetErrorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") {
                        dismiss()
                    }
                }
            }
        }
    }
}
