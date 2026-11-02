//
//  QuickAddService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//

import Foundation

enum QuickAddError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidResult
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Hızlı Ekle servis adresi geçersiz."
        case .invalidResponse:
            return "Yapay zekâ yanıtı okunamadı."
        case .invalidResult:
            return "İşlem bilgileri anlaşılamadı. Daha açık bir cümle deneyin."
        case .serviceUnavailable:
            return "Hızlı Ekle şu anda kullanılamıyor."
        }
    }
}

struct QuickAddService {

    // Cloudflare'ın verdiği gerçek Worker adresiyle değiştir.
    private let baseURL = "https://kalan-quick-add.kilicaslanomerkuf.workers.dev"

    func analyze(
        text: String,
        transactionType: Int
    ) async throws -> QuickAddResult {

        guard let url = URL(
            string: "\(baseURL)/quick-add"
        ) else {
            throw QuickAddError.invalidURL
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "yyyy-MM-dd"

        let requestBody = QuickAddRequest(
            text: text,
            referenceDate: formatter.string(from: Date()),
            transactionType: transactionType == 0
                ? "income"
                : "payment"
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickAddError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {

            let responseBody = String(
                data: data,
                encoding: .utf8
            ) ?? "Yanıt okunamadı"

            print("========== QUICK ADD ERROR ==========")
            print("HTTP Status:", httpResponse.statusCode)
            print("Response:", responseBody)
            print("=====================================")

            if httpResponse.statusCode == 422 {
                throw QuickAddError.invalidResult
            }

            throw QuickAddError.serviceUnavailable
        }

        return try JSONDecoder().decode(
            QuickAddResult.self,
            from: data
        )
    }
}

