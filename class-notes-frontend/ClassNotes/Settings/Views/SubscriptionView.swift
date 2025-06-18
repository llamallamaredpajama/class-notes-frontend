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
    @State private var showingFeatureComparison = false

    // Subscription tiers as specified
    private let tiers = [
        SubscriptionTier(
            name: "Basic",
            price: "$5.99/month",
            color: .blue,
            icon: "star",
            features: [
                "100 lessons per month",
                "Basic AI summaries",
                "Text-only transcription",
                "PDF export",
                "7-day history",
                "Basic search"
            ],
            limitations: [
                "No advanced AI analysis",
                "No drawing support",
                "No collaborative features",
                "Standard processing speed"
            ]
        ),
        SubscriptionTier(
            name: "Advanced",
            price: "$17.99/month",
            color: .purple,
            icon: "star.circle",
            isPopular: true,
            features: [
                "500 lessons per month",
                "Advanced AI analysis",
                "Audio + text transcription",
                "Multiple export formats",
                "30-day history",
                "Advanced search",
                "Drawing support",
                "Priority processing"
            ],
            limitations: [
                "Limited collaboration",
                "Monthly lesson limit"
            ]
        ),
        SubscriptionTier(
            name: "Pro",
            price: "$34.99/month",
            color: .orange,
            icon: "star.circle.fill",
            features: [
                "Unlimited lessons",
                "Premium AI analysis",
                "All transcription types",
                "All export formats",
                "Unlimited history",
                "Advanced search + filters",
                "Full drawing support",
                "Real-time collaboration",
                "Priority support",
                "API access"
            ],
            limitations: []
        )
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Current subscription status
                currentStatusSection

                // Subscription tiers
                tiersSection

                // Feature comparison button
                featureComparisonButton

                // Restore purchases
                restorePurchasesSection

                // Legal
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
        .sheet(isPresented: $showingFeatureComparison) {
            FeatureComparisonView(tiers: tiers)
        }
        .task {
            await subscriptionService.loadProducts()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Unlock Your Learning Potential")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Choose the plan that fits your study needs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical)
    }

    private var currentStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Plan")
                .font(.headline)

            HStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let description = statusDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if subscriptionService.subscriptionStatus == .free {
                    Text("FREE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.1))
            )
        }
    }

    private var tiersSection: some View {
        VStack(spacing: 16) {
            ForEach(tiers) { tier in
                SubscriptionTierCard(
                    tier: tier,
                    isProcessing: subscriptionService.isProcessingPurchase,
                    currentTier: getCurrentTierName(),
                    onPurchase: {
                        purchaseTier(tier)
                    }
                )
            }
        }
    }

    private var featureComparisonButton: some View {
        Button {
            showingFeatureComparison = true
        } label: {
            Label("Compare All Features", systemImage: "chart.bar.doc.horizontal")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

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

    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://classnotes.app/terms")!)
                    .font(.caption)

                Link("Privacy Policy", destination: URL(string: "https://classnotes.app/privacy")!)
                    .font(.caption)
            }

            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        switch subscriptionService.subscriptionStatus {
        case .active: return "checkmark.circle.fill"
        case .expired: return "exclamationmark.circle"
        case .cancelled: return "xmark.circle"
        case .gracePeriod: return "clock.arrow.circlepath"
        default: return "person.circle"
        }
    }

    private var statusColor: Color {
        switch subscriptionService.subscriptionStatus {
        case .active: return .green
        case .expired, .cancelled: return .orange
        case .gracePeriod: return .yellow
        default: return .gray
        }
    }

    private var statusTitle: String {
        switch subscriptionService.subscriptionStatus {
        case .active(let tier, _):
            return "\(tier.rawValue) Plan Active"
        case .expired:
            return "Subscription Expired"
        case .cancelled:
            return "Subscription Cancelled"
        case .gracePeriod:
            return "In Grace Period"
        case .free:
            return "Free Plan"
        case .unknown:
            return "Loading..."
        }
    }

    private var statusDescription: String? {
        switch subscriptionService.subscriptionStatus {
        case .active(_, let expiresAt):
            return "Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
        case .cancelled(let expiresAt):
            return "Access until \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
        case .gracePeriod(_, let expiresAt):
            return "Grace period ends \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
        case .expired:
            return "Renew to regain access to premium features"
        case .free:
            return "Limited to 10 lessons per month"
        default:
            return nil
        }
    }

    // MARK: - Methods

    private func getCurrentTierName() -> String? {
        switch subscriptionService.subscriptionStatus {
        case .active(let tier, _):
            return tier.rawValue
        default:
            return nil
        }
    }

    private func purchaseTier(_ tier: SubscriptionTier) {
        // Map tier to actual product
        guard let product = subscriptionService.availableProducts.first(where: { 
            $0.id.lowercased().contains(tier.name.lowercased())
        }) else { return }
        
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
                restoreMessage = "Failed to restore purchases: \(error.localizedDescription)"
            }
            showingRestoreAlert = true
        }
    }
}

// MARK: - Subscription Tier Card

struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isProcessing: Bool
    let currentTier: String?
    let onPurchase: () -> Void
    
    private var isCurrentTier: Bool {
        currentTier == tier.name
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: tier.icon)
                            .font(.title2)
                            .foregroundColor(tier.color)
                        
                        Text(tier.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if tier.isPopular {
                            Text("MOST POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tier.color)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(tier.price)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if isCurrentTier {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(tier.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(tier.color, lineWidth: 1)
                        )
                }
            }
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tier.features.prefix(5), id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(tier.color)
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
                
                if tier.features.count > 5 {
                    Text("+ \(tier.features.count - 5) more features")
                        .font(.caption)
                        .foregroundColor(tier.color)
                }
            }
            
            // Purchase button
            Button(action: onPurchase) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else if isCurrentTier {
                    Text("Current Plan")
                } else {
                    Text("Subscribe")
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .tint(tier.color)
            .disabled(isProcessing || isCurrentTier)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(tier.isPopular ? tier.color.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Feature Comparison View

struct FeatureComparisonView: View {
    let tiers: [SubscriptionTier]
    @Environment(\.dismiss) private var dismiss
    
    private let allFeatures = [
        "Lessons per month",
        "AI summaries",
        "Transcription types",
        "Export formats",
        "History retention",
        "Search capabilities",
        "Drawing support",
        "Processing speed",
        "Collaboration",
        "Priority support",
        "API access"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        Text("Features")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        ForEach(tiers) { tier in
                            VStack(spacing: 4) {
                                Image(systemName: tier.icon)
                                    .font(.title3)
                                    .foregroundColor(tier.color)
                                
                                Text(tier.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(tier.price)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                    
                    // Feature rows
                    ForEach(allFeatures, id: \.self) { feature in
                        HStack(spacing: 0) {
                            Text(feature)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            
                            ForEach(tiers) { tier in
                                FeatureCell(
                                    feature: feature,
                                    tier: tier
                                )
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }
                        .background(
                            allFeatures.firstIndex(of: feature)! % 2 == 0 
                                ? Color.clear 
                                : Color.secondary.opacity(0.05)
                        )
                    }
                }
            }
            .navigationTitle("Compare Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureCell: View {
    let feature: String
    let tier: SubscriptionTier
    
    private var value: String {
        switch (feature, tier.name) {
        case ("Lessons per month", "Basic"): return "100"
        case ("Lessons per month", "Advanced"): return "500"
        case ("Lessons per month", "Pro"): return "Unlimited"
        case ("History retention", "Basic"): return "7 days"
        case ("History retention", "Advanced"): return "30 days"
        case ("History retention", "Pro"): return "Unlimited"
        default:
            return tier.features.contains(where: { $0.lowercased().contains(feature.lowercased()) }) 
                ? "✓" 
                : "—"
        }
    }
    
    private var color: Color {
        value == "—" ? .secondary : tier.color
    }
    
    var body: some View {
        Text(value)
            .font(.body)
            .fontWeight(value == "✓" ? .medium : .regular)
            .foregroundColor(color)
    }
}

// MARK: - Supporting Types

struct SubscriptionTier: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let color: Color
    let icon: String
    var isPopular: Bool = false
    let features: [String]
    let limitations: [String]
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
