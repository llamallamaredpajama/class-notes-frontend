import SwiftUI

/// A simple test view to verify gRPC connectivity
struct GRPCTestView: View {
    @State private var isLoading = false
    @State private var testResult: String = "Not tested yet"
    @State private var resultColor: Color = .gray

    var body: some View {
        VStack(spacing: 20) {
            Text("gRPC Connection Test")
                .font(.largeTitle)
                .padding()

            Text(testResult)
                .font(.title2)
                .foregroundColor(resultColor)
                .padding()

            Button(action: runTest) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Run gRPC Test")
                        .font(.headline)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Text("This will attempt to connect to localhost:8080")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    private func runTest() {
        isLoading = true
        testResult = "Testing..."
        resultColor = .blue

        Task {
            let success = await MinimalGRPCService.shared.testConnection()

            await MainActor.run {
                isLoading = false
                if success {
                    testResult = "✅ Connection Successful!"
                    resultColor = .green
                } else {
                    testResult = "❌ Connection Failed"
                    resultColor = .red
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GRPCTestView()
}
