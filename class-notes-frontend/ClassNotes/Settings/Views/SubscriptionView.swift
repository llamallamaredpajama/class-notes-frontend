// 2. Apple frameworks
import StoreKit
// 1. Standard library
import SwiftUI

/// View for managing subscriptions and in-app purchases
struct SubscriptionView: View {
    // MARK: - Properties

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedProduct: Product?
    @State private var showingPurchaseError = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""

    private let benefits = [
        SubscriptionBenefit(
            tier: .basic,
            title: "Basic Plan",
            features: [
                "Up to 100 lessons per month",
                "Basic AI summaries",
                "Text search",
                "Export to PDF",
                "7-day history",
            ],
            icon: "star",
            color: .blue
        ),
        SubscriptionBenefit(
            tier: .pro,
            title: "Pro Plan",
            features: [
                "Unlimited lessons",
                "Advanced AI analysis",
                "Voice search",
                "Export to multiple formats",
                "Unlimited history",
                "Priority support",
                "Collaborative features",
            ],
            icon: "star.fill",
            color: .purple
        ),
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current status
                currentStatusSection

                // Available plans
                if !subscriptionService.availableProducts.isEmpty {
                    plansSection
                }

                // Benefits comparison
                benefitsSection

                // Restore purchases
                restorePurchasesSection

                // Terms and privacy
                legalSection
            }
            .padding()
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.large)
        .alert("Purchase Error", isPresented: $showingPurchaseError) {
            Button("OK") {}
        } message: {
            Text(subscriptionService.error?.localizedDescription ?? "An error occurred")
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") {}
        } message: {
            Text(restoreMessage)
        }
        .task {
            // Refresh products on view appear
            await subscriptionService.loadProducts()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)

            HStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let statusDescription = statusDescription {
                        Text(statusDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.1))
            )
        }
    }

    @ViewBuilder
    private var plansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Plans")
                .font(.headline)

            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                SubscriptionProductView(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isProcessing: subscriptionService.isProcessingPurchase
                ) {
                    purchaseProduct(product)
                }
            }
        }
    }

    @ViewBuilder
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan Benefits")
                .font(.headline)

            ForEach(benefits) { benefit in
                BenefitCard(benefit: benefit)
            }
        }
    }

    @ViewBuilder
    private var restorePurchasesSection: some View {
        VStack(spacing: 12) {
            Button(action: restorePurchases) {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("Restore previous purchases from the App Store")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var legalSection: some View {
        VStack(spacing: 8) {
            Link("Terms of Service", destination: URL(string: "https://classnotes.app/terms")!)
                .font(.caption)

            Link("Privacy Policy", destination: URL(string: "https://classnotes.app/privacy")!)
                .font(.caption)

            Text(
                "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period."
            )
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
        }
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        switch subscriptionService.subscriptionStatus {
        case .active(let tier, _):
            return tier == .pro ? "star.fill" : "star"
        case .expired:
            return "exclamationmark.circle"
        case .cancelled:
            return "xmark.circle"
        case .gracePeriod:
            return "clock.arrow.circlepath"
        default:
            return "person.circle"
        }
    }

    private var statusColor: Color {
        switch subscriptionService.subscriptionStatus {
        case .active(let tier, _):
            return tier == .pro ? .purple : .blue
        case .expired, .cancelled:
            return .orange
        case .gracePeriod:
            return .yellow
        default:
            return .gray
        }
    }

    private var statusTitle: String {
        switch subscriptionService.subscriptionStatus {
        case .active(let tier, _):
            return "\(tier == .pro ? "Pro" : "Basic") Subscriber"
        case .expired:
            return "Subscription Expired"
        case .cancelled:
            return "Subscription Cancelled"
        case .gracePeriod(let tier, _):
            return "\(tier == .pro ? "Pro" : "Basic") - Grace Period"
        case .free:
            return "Free Plan"
        case .unknown:
            return "Loading..."
        }
    }

    private var statusDescription: String? {
        switch subscriptionService.subscriptionStatus {
        case .active(_, let expiresAt):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Renews \(formatter.string(from: expiresAt))"
        case .cancelled(let expiresAt):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Access until \(formatter.string(from: expiresAt))"
        case .gracePeriod(_, let expiresAt):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Grace period ends \(formatter.string(from: expiresAt))"
        case .expired:
            return "Renew to regain access"
        default:
            return nil
        }
    }

    // MARK: - Actions

    private func purchaseProduct(_ product: Product) {
        selectedProduct = product

        Task {
            do {
                try await subscriptionService.purchase(product)
            } catch {
                showingPurchaseError = true
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restorePurchases()
                restoreMessage = "Purchases restored successfully!"
            } catch {
                restoreMessage = error.localizedDescription
            }
            showingRestoreAlert = true
        }
    }
}

// MARK: - Supporting Views

struct SubscriptionProductView: View {
    let product: Product
    let isSelected: Bool
    let isProcessing: Bool
    let onPurchase: () -> Void

    private var isMonthly: Bool {
        product.id.contains("monthly")
    }

    private var isPro: Bool {
        product.id.contains("pro")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isPro ? "Pro" : "Basic")
                            .font(.headline)

                        if isPro {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple)
                                .cornerRadius(4)
                        }
                    }

                    Text(isMonthly ? "Monthly" : "Annual")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)

                    if !isMonthly {
                        Text("Save 20%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            Button(action: onPurchase) {
                Group {
                    if isProcessing && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Text("Subscribe")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isPro ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
}

struct BenefitCard: View {
    let benefit: SubscriptionBenefit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: benefit.icon)
                    .font(.title2)
                    .foregroundColor(benefit.color)

                Text(benefit.title)
                    .font(.headline)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(benefit.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(benefit.color)

                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(benefit.color.opacity(0.1))
        )
    }
}

// MARK: - Supporting Types

struct SubscriptionBenefit: Identifiable {
    let id = UUID()
    let tier: SubscriptionService.SubscriptionTier
    let title: String
    let features: [String]
    let icon: String
    let color: Color
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
