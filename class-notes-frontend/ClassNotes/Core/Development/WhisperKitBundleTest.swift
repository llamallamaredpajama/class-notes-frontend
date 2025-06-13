import Foundation
import SwiftUI

/// Test view to verify WhisperKit models are correctly bundled
struct WhisperKitBundleTest: View {
    @State private var testResults: [TestResult] = []

    struct TestResult: Identifiable {
        let id = UUID()
        let name: String
        let passed: Bool
        let details: String
    }

    var body: some View {
        NavigationView {
            List(testResults) { result in
                HStack {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.passed ? .green : .red)

                    VStack(alignment: .leading) {
                        Text(result.name)
                            .font(.headline)
                        Text(result.details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("WhisperKit Bundle Test")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Run Tests") {
                        runTests()
                    }
                }
            }
        }
        .onAppear {
            runTests()
        }
    }

    private func runTests() {
        testResults.removeAll()

        // Test 1: Check if WhisperKitModels folder exists in bundle
        if let modelsURL = Bundle.main.url(forResource: "WhisperKitModels", withExtension: nil) {
            testResults.append(
                TestResult(
                    name: "WhisperKitModels Folder",
                    passed: true,
                    details: "Found at: \(modelsURL.lastPathComponent)"
                ))

            // Test 2: Check for openai_whisper-medium subfolder
            let mediumModelURL = modelsURL.appendingPathComponent("openai_whisper-medium")
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: mediumModelURL.path) {
                testResults.append(
                    TestResult(
                        name: "Medium Model Folder",
                        passed: true,
                        details: "openai_whisper-medium exists"
                    ))

                // Test 3: Check for required model files
                let requiredFiles = [
                    "AudioEncoder.mlmodelc",
                    "TextDecoder.mlmodelc",
                    "MelSpectrogram.mlmodelc",
                    "config.json",
                    "generation_config.json",
                ]

                var missingFiles: [String] = []
                for file in requiredFiles {
                    let fileURL = mediumModelURL.appendingPathComponent(file)
                    if !fileManager.fileExists(atPath: fileURL.path) {
                        missingFiles.append(file)
                    }
                }

                testResults.append(
                    TestResult(
                        name: "Required Model Files",
                        passed: missingFiles.isEmpty,
                        details: missingFiles.isEmpty
                            ? "All files present"
                            : "Missing: \(missingFiles.joined(separator: ", "))"
                    ))

                // Test 4: Check file sizes
                if missingFiles.isEmpty {
                    do {
                        let audioEncoderURL = mediumModelURL.appendingPathComponent(
                            "AudioEncoder.mlmodelc")
                        let textDecoderURL = mediumModelURL.appendingPathComponent(
                            "TextDecoder.mlmodelc")

                        let audioEncoderSize =
                            try fileManager.attributesOfItem(atPath: audioEncoderURL.path)[.size]
                            as? Int64 ?? 0
                        let textDecoderSize =
                            try fileManager.attributesOfItem(atPath: textDecoderURL.path)[.size]
                            as? Int64 ?? 0

                        let audioEncoderMB = Double(audioEncoderSize) / 1024 / 1024
                        let textDecoderMB = Double(textDecoderSize) / 1024 / 1024

                        testResults.append(
                            TestResult(
                                name: "Model Sizes",
                                passed: audioEncoderMB > 500 && textDecoderMB > 800,
                                details: String(
                                    format: "AudioEncoder: %.0fMB, TextDecoder: %.0fMB",
                                    audioEncoderMB, textDecoderMB)
                            ))
                    } catch {
                        testResults.append(
                            TestResult(
                                name: "Model Sizes",
                                passed: false,
                                details: "Error checking sizes: \(error.localizedDescription)"
                            ))
                    }
                }

            } else {
                testResults.append(
                    TestResult(
                        name: "Medium Model Folder",
                        passed: false,
                        details: "openai_whisper-medium not found"
                    ))
            }

        } else {
            testResults.append(
                TestResult(
                    name: "WhisperKitModels Folder",
                    passed: false,
                    details: "Not found in app bundle - Check Xcode setup"
                ))
        }

        // Test 5: Try to initialize WhisperKitService
        testResults.append(
            TestResult(
                name: "Bundle Structure",
                passed: Bundle.main.url(forResource: "WhisperKitModels", withExtension: nil) != nil,
                details: "Folder reference (blue folder) required in Xcode"
            ))
    }
}

struct WhisperKitBundleTest_Previews: PreviewProvider {
    static var previews: some View {
        WhisperKitBundleTest()
    }
}
