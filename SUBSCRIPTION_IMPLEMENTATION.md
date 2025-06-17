# iOS Subscription Implementation Guide

This guide documents the implementation of the iOS subscription system that integrates with the backend tier management system.

## Overview

The subscription implementation provides:
- **StoreKit 2 Integration**: Modern async/await purchase flow
- **Backend Receipt Validation**: Server-side validation via gRPC
- **Tier Management**: Free, Basic ($5.99), Advanced ($17.99), Pro ($34.99)
- **Usage Tracking**: Real-time quota monitoring
- **Device Management**: Multi-device support with limits per tier

## Architecture

### 1. SubscriptionService (`ClassNotes/Core/Services/SubscriptionService.swift`)

Central service managing all subscription operations:

```swift
@MainActor
final class SubscriptionService: NSObject, ObservableObject {
    // Published properties for UI binding
    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var usageStatistics: UsageStatistics?
    
    // Core functionality
    func purchase(_ product: Product) async throws
    func restorePurchases() async throws
    func refreshSubscriptionStatus() async
    func registerDevice() async throws
}
```

Key features:
- **Transaction Monitoring**: Listens for StoreKit updates
- **Automatic Receipt Validation**: Validates with backend on purchase
- **Retry Logic**: Exponential backoff for network failures
- **Error Handling**: Comprehensive error states

### 2. SubscriptionView (`ClassNotes/Settings/Views/SubscriptionView.swift`)

SwiftUI view for subscription management:

```swift
struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        ScrollView {
            currentStatusSection
            plansSection
            benefitsSection
            restorePurchasesSection
        }
    }
}
```

Features:
- Current subscription status display
- Available plans with pricing
- Usage statistics visualization
- Restore purchases functionality

### 3. Proto Definitions (`ClassNotes/Core/Networking/gRPC/Protos/subscription.proto`)

Defines the gRPC service interface:

```protobuf
service SubscriptionService {
    rpc ValidateReceipt(ValidateReceiptRequest) returns (ValidateReceiptResponse);
    rpc GetSubscriptionStatus(google.protobuf.Empty) returns (SubscriptionStatusResponse);
    rpc GetUsageStatistics(google.protobuf.Empty) returns (UsageStatisticsResponse);
    rpc RegisterDevice(RegisterDeviceRequest) returns (RegisterDeviceResponse);
}
```

## Setup Instructions

### 1. Generate Proto Files

```bash
# Install dependencies
brew install protobuf
brew install swift-protobuf
brew install grpc-swift

# Generate Swift code
cd Frontend/class-notes-frontend
./Scripts/generate-subscription-proto.sh
```

### 2. Configure App Store Connect

1. Create subscription products:
   - `com.classnotes.subscription.monthly.basic` - $5.99
   - `com.classnotes.subscription.monthly.advanced` - $17.99
   - `com.classnotes.subscription.monthly.pro` - $34.99
   - Yearly variants with 20% discount

2. Configure server-to-server notifications:
   - URL: `https://api.classnotes.app/webhooks/apple`
   - Version: Version 2

3. Set up shared secret for receipt validation

### 3. Add StoreKit Configuration (Development)

Create `StoreKit.storekit` configuration file for testing:

```json
{
  "products": [
    {
      "id": "com.classnotes.subscription.monthly.basic",
      "type": "autoRenewable",
      "price": 5.99,
      "subscriptionGroupID": "classnotes_subscriptions"
    }
    // ... other products
  ]
}
```

## Implementation Flow

### Purchase Flow

```
1. User selects subscription plan
2. iOS initiates StoreKit purchase
3. On success, app gets receipt
4. App sends receipt to backend via gRPC
5. Backend validates with Apple
6. Backend updates user profile & quotas
7. App refreshes subscription status
8. UI updates to reflect new tier
```

### Status Check Flow

```
1. App launches or resumes
2. SubscriptionService checks status
3. gRPC call to backend with auth token
4. Backend returns current tier & usage
5. UI updates accordingly
```

## Testing

### Unit Tests

```swift
func testPurchaseFlow() async throws {
    // Mock StoreKit transaction
    let mockProduct = MockProduct(id: "com.classnotes.subscription.monthly.basic")
    
    // Mock gRPC response
    mockGRPCClient.validateReceiptResponse = ValidateReceiptResponse.with {
        $0.isValid = true
        $0.tier = "BASIC"
    }
    
    // Test purchase
    try await subscriptionService.purchase(mockProduct)
    
    // Verify status updated
    XCTAssertEqual(subscriptionService.subscriptionStatus, .active(tier: .basic))
}
```

### Integration Tests

1. Test with StoreKit Testing in Xcode
2. Use sandbox environment for receipt validation
3. Test all subscription scenarios:
   - New purchase
   - Renewal
   - Cancellation
   - Grace period
   - Restoration

## Monitoring

### Key Metrics

1. **Subscription Metrics**
   - Conversion rate (free → paid)
   - Churn rate by tier
   - Revenue per user

2. **Technical Metrics**
   - Receipt validation failures
   - Network errors
   - Transaction completion rate

### Error Tracking

```swift
enum SubscriptionError: LocalizedError {
    case receiptNotFound
    case notAuthenticated
    case verificationFailed
    case invalidReceipt(String)
    // ... other cases
}
```

## Best Practices

### 1. Always Validate Server-Side
Never trust client-side validation. Always send receipts to backend.

### 2. Handle Network Failures Gracefully
Implement retry logic with exponential backoff.

### 3. Cache Subscription Status
Store status locally but refresh on app launch and resume.

### 4. Provide Clear Upgrade Path
Show benefits and current usage to encourage upgrades.

### 5. Test Thoroughly
Use StoreKit Testing and sandbox environment extensively.

## Troubleshooting

### Common Issues

1. **"No such module 'ClassNotesGRPC'"**
   - Run proto generation script
   - Clean build folder
   - Check Package.swift dependencies

2. **Receipt validation fails**
   - Check bundle ID matches App Store Connect
   - Verify shared secret is correct
   - Ensure using correct environment (sandbox vs production)

3. **Products not loading**
   - Verify product IDs match exactly
   - Check App Store Connect configuration
   - Ensure agreements are signed

## Security Considerations

1. **Receipt Validation**: Always performed server-side
2. **Token Management**: Auth tokens stored in Keychain
3. **Device Limits**: Enforced by backend
4. **Data Encryption**: All gRPC calls use TLS

## Future Enhancements

1. **Promotional Offers**: Support discount codes
2. **Family Sharing**: Enable subscription sharing
3. **Win-back Campaigns**: Target lapsed subscribers
4. **A/B Testing**: Price and feature experiments

This implementation follows Apple's guidelines and integrates seamlessly with the backend tier management system described in `Backend/TIER_MANAGEMENT_GUIDE.md`. 