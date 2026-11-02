
import SwiftUI
import SwiftData

struct KalanChatView: View {

    @Query private var incomes: [Income]
    @Query private var payments: [Payment]
    @Query private var occurrences: [PaymentOccurrence]
    @Query private var incomeChanges: [IncomeAmountChange]
    @Query private var incomeOverrides: [IncomeOccurrenceOverride]

    @State private var messages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: "Merhaba! Ben KALAN Chat. Gelirlerin, ödemelerin ve bütçen hakkında sorular sorabilirsin."
        )
    ]

    @State private var question = ""
    @State private var isLoading = false

    private let chatService = KalanChatService()

    private let green = Color(
        red: 15 / 255.0,
        green: 122 / 255.0,
        blue: 67 / 255.0
    )

    private let background = Color(
        red: 240 / 255.0,
        green: 248 / 255.0,
        blue: 245 / 255.0
    )

    private let suggestions = [
        "Bu ay ne kadar gelir elde ettim?",
        "Bu ay ne kadar ödeme yaptım?",
        "En çok hangi kategoriye harcadım?",
        "Geçen aya göre daha fazla mı ödedim?"
    ]

    var body: some View {
        VStack(spacing: 0) {

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {

                        ForEach(messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if messages.count == 1 {
                            suggestionSection
                        }

                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("KALAN düşünüyor...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(
                                last.id,
                                anchor: .bottom
                            )
                        }
                    }
                }
            }

            inputBar
        }
        .background(background.ignoresSafeArea())
        .navigationTitle("KALAN Chat")
        .navigationBarTitleDisplayMode(.inline)
        .tint(green)
    }

    private func messageBubble(
        _ message: ChatMessage
    ) -> some View {
        HStack(alignment: .top) {
            if message.role == .user {
                Spacer(minLength: 45)
            }

            Text(message.text)
                .font(.custom("AvenirNext-Regular", size: 14))
                .foregroundStyle(
                    message.role == .user
                        ? Color.white
                        : Color.primary
                )
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            message.role == .user
                                ? green
                                : Color.white
                        )
                )

            if message.role == .assistant {
                Spacer(minLength: 45)
            }
        }
    }

    private var suggestionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ÖNERİLEN SORULAR")
                .font(.custom("AvenirNext-DemiBold", size: 12))
                .foregroundStyle(.secondary)

            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    question = suggestion
                    sendMessage()
                } label: {
                    HStack {
                        Text(suggestion)
                            .font(.custom("AvenirNext-Medium", size: 13))
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                    }
                    .foregroundStyle(green)
                    .padding(13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField(
                "Finansların hakkında sor...",
                text: $question,
                axis: .vertical
            )
            .lineLimit(1...3)
            .font(.custom("AvenirNext-Regular", size: 14))
            .submitLabel(.send)
            .onSubmit {
                sendMessage()
            }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(green))
            }
            .disabled(
                isLoading ||
                question.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func sendMessage() {
        let text = question.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !text.isEmpty, !isLoading else {
            return
        }

        question = ""
        messages.append(
            ChatMessage(role: .user, text: text)
        )

        isLoading = true

        Task {
            do {
                let intent = try await chatService.classify(text)

                let answer = ChatAnalyticsService.answer(
                    intent: intent,
                    incomes: incomes,
                    payments: payments,
                    occurrences: occurrences,
                    changes: incomeChanges,
                    overrides: incomeOverrides
                )

                messages.append(
                    ChatMessage(role: .assistant, text: answer)
                )

            } catch {
                print("KALAN CHAT ERROR:", error)

                messages.append(
                    ChatMessage(
                        role: .assistant,
                        text: error.localizedDescription
                    )
                )
            }

            isLoading = false
        }
    }
}
