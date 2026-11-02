//
//  KalanChatService.swift
//  Kalan
//
//  Created by Ömer Faruk Kılıçaslan on 2.11.2026.
//

import Foundation

enum KalanChatError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serviceUnavailable
    case invalidQuestion
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Chat servis adresi geçersiz."
        case .invalidResponse:
            return "Yapay zekâ yanıtı okunamadı."
        case .serviceUnavailable:
            return "KALAN Chat şu anda kullanılamıyor."
        case .invalidQuestion:
            return "Soruyu anlayamadım. Daha açık yazmayı deneyebilirsin."
        case .rateLimited:
            return "Çok fazla soru gönderildi. Biraz sonra tekrar deneyebilirsin."
        }
    }
}

struct KalanChatService {

    private let baseURL =
        "https://kalan-quick-add.kilicaslanomerkuf.workers.dev"

    func classify(_ question: String) async throws -> ChatIntentResult {

        guard let url = URL(string: "\(baseURL)/chat-intent") else {
            throw KalanChatError.invalidURL
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "yyyy-MM-dd"

        let body = ChatIntentRequest(
            text: question,
            referenceDate: formatter.string(from: Date())
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let response = response as? HTTPURLResponse else {
            throw KalanChatError.invalidResponse
        }

        guard (200...299).contains(response.statusCode) else {

            let responseBody = String(
                data: data,
                encoding: .utf8
            ) ?? "Yanıt okunamadı"

            print("========== KALAN CHAT ERROR ==========")
            print("HTTP Status:", response.statusCode)
            print("Response:", responseBody)
            print("======================================")

            if response.statusCode == 429 {
                throw KalanChatError.rateLimited
            }

            if response.statusCode == 400 ||
                response.statusCode == 422 {
                throw KalanChatError.invalidQuestion
            }

            throw KalanChatError.serviceUnavailable
        }

        return try JSONDecoder().decode(
            ChatIntentResult.self,
            from: data
        )
    }
}

