//
//  DemoPayment.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 30.10.2026.
//

import Foundation

struct DemoPayment: Identifiable {
    let id: UUID
    var name: String
    var amount: Decimal
    var dueDate: Date
    var isPaid: Bool

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        dueDate: Date,
        isPaid: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
    }
}

extension DemoPayment {
    static var samples: [DemoPayment] {
        let calendar = Calendar.current

        func date(day: Int) -> Date {
            calendar.date(
                bySetting: .day,
                value: day,
                of: Date()
            ) ?? Date()
        }

        return [
            DemoPayment(
                name: "Elektrik Faturası",
                amount: 1850,
                dueDate: date(day: 3)
            ),
            DemoPayment(
                name: "İnternet",
                amount: 650,
                dueDate: date(day: 5)
            ),
            DemoPayment(
                name: "Kredi Taksiti",
                amount: 8500,
                dueDate: date(day: 8)
            ),
            DemoPayment(
                name: "Telefon Faturası",
                amount: 450,
                dueDate: date(day: 10)
            )
        ]
    }
}
