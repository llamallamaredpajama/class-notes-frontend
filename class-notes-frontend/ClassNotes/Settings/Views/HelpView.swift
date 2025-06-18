// 1. Standard library
import SwiftUI

/// Help and support view with FAQs and contact options
struct HelpView: View {
    // MARK: - Properties
    @State private var searchText = ""
    @State private var expandedSections: Set<UUID> = []

    private let faqCategories = [
        FAQCategory(
            title: "Getting Started",
            icon: "play.circle",
            questions: [
                FAQ(
                    question: "How do I record my first note?",
                    answer:
                        "Tap the '+' button on the home screen, then press the record button to start capturing audio. Tap stop when you're finished."
                ),
                FAQ(
                    question: "Can I import existing audio files?",
                    answer:
                        "Yes! You can import audio files from your device by tapping the import button in the recording screen."
                ),
                FAQ(
                    question: "How do I organize my notes?",
                    answer:
                        "Notes are automatically organized by date. You can also add tags and search for specific content."
                ),
            ]
        ),
        FAQCategory(
            title: "Transcription",
            icon: "text.bubble",
            questions: [
                FAQ(
                    question: "How accurate is the transcription?",
                    answer:
                        "Our AI-powered transcription is highly accurate, typically achieving 95%+ accuracy for clear audio in supported languages."
                ),
                FAQ(
                    question: "Which languages are supported?",
                    answer:
                        "Currently, we support English, Spanish, French, and German. More languages are coming soon!"
                ),
                FAQ(
                    question: "Can I edit transcriptions?",
                    answer:
                        "Yes, you can edit any transcription by tapping on the text in the note detail view."
                ),
            ]
        ),
        FAQCategory(
            title: "Account & Billing",
            icon: "creditcard",
            questions: [
                FAQ(
                    question: "How do I upgrade my plan?",
                    answer:
                        "Go to Settings > Subscription to view and upgrade your plan. You can choose between monthly and annual billing."
                ),
                FAQ(
                    question: "Can I cancel my subscription?",
                    answer:
                        "Yes, you can cancel anytime from Settings > Subscription. You'll retain access until the end of your billing period."
                ),
                FAQ(
                    question: "Do you offer student discounts?",
                    answer:
                        "Yes! Students with a valid .edu email address receive 50% off all plans."),
            ]
        ),
        FAQCategory(
            title: "Privacy & Security",
            icon: "lock.shield",
            questions: [
                FAQ(
                    question: "Is my data secure?",
                    answer:
                        "All data is encrypted both in transit and at rest. We use industry-standard security practices to protect your information."
                ),
                FAQ(
                    question: "Can I export my data?",
                    answer:
                        "Yes, you can export all your data at any time from Settings > Privacy > Export My Data."
                ),
                FAQ(
                    question: "Do you sell my data?",
                    answer: "No, we never sell your personal data. Your privacy is our priority."),
            ]
        ),
    ]

    private var filteredCategories: [FAQCategory] {
        if searchText.isEmpty {
            return faqCategories
        }

        return faqCategories.compactMap { category in
            let filteredQuestions = category.questions.filter { faq in
                faq.question.localizedCaseInsensitiveContains(searchText)
                    || faq.answer.localizedCaseInsensitiveContains(searchText)
            }

            if !filteredQuestions.isEmpty {
                return FAQCategory(
                    title: category.title,
                    icon: category.icon,
                    questions: filteredQuestions
                )
            }

            return nil
        }
    }

    // MARK: - Body
    var body: some View {
        List {
            if !searchText.isEmpty && filteredCategories.isEmpty {
                noResultsView
            } else {
                ForEach(filteredCategories) { category in
                    faqCategorySection(category)
                }
            }

            contactSection
        }
        .searchable(text: $searchText, prompt: "Search help topics")
        .navigationTitle("Help & Support")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
        #endif
    }

    // MARK: - Views
    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No results found")
                .font(.headline)

            Text("Try searching with different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func faqCategorySection(_ category: FAQCategory) -> some View {
        Section {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedSections.contains(category.id) },
                    set: { isExpanded in
                        if isExpanded {
                            expandedSections.insert(category.id)
                        } else {
                            expandedSections.remove(category.id)
                        }
                    }
                )
            ) {
                ForEach(category.questions) { faq in
                    FAQRow(faq: faq)
                        .padding(.vertical, 4)
                }
            } label: {
                Label(category.title, systemImage: category.icon)
                    .font(.headline)
            }
        }
    }

    @ViewBuilder
    private var contactSection: some View {
        Section("Still need help?") {
            Link(destination: URL(string: "mailto:support@classnotes.app")!) {
                Label("Email Support", systemImage: "envelope")
            }

            Link(destination: URL(string: "https://classnotes.app/support")!) {
                Label("Visit Support Center", systemImage: "globe")
            }

            NavigationLink(destination: ChatSupportView()) {
                Label("Live Chat", systemImage: "message")
            }
        }
    }
}

// MARK: - Supporting Types
struct FAQCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let questions: [FAQ]
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - Supporting Views
struct FAQRow: View {
    let faq: FAQ
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(faq.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(faq.answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct ChatSupportView: View {
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! How can I help you today?", isUser: false)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.blue))
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Live Chat")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        messages.append(ChatMessage(text: messageText, isUser: true))

        // Simulate support response
        let _ = messageText
        messageText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            messages.append(
                ChatMessage(
                    text: "Thanks for your message. A support agent will respond shortly.",
                    isUser: false
                ))
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(message.isUser ? .white : .primary)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser { Spacer() }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HelpView()
    }
}
