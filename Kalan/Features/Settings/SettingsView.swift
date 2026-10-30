//
//  SettingsView.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("salaryDay")
    private var salaryDay = 15

    @AppStorage("preferredCurrency")
    private var preferredCurrency = "TRY"

    @AppStorage("appearance")
    private var appearance = "system"

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
                        Text("Sistem").tag("system")
                        Text("Açık").tag("light")
                        Text("Koyu").tag("dark")
                    }
                }

                Section("Uygulama") {
                    LabeledContent("Uygulama", value: "KALAN")
                    LabeledContent("Sürüm", value: "1.0")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
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
