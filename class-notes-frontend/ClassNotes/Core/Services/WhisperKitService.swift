import Foundation
import WhisperKit

/// Service for handling speech-to-text transcription using WhisperKit
@MainActor
public class WhisperKitService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isLoading = false
    @Published public private(set) var isTranscribing = false
    @Published public private(set) var modelState: ModelState = .notLoaded
    @Published public private(set) var transcriptionProgress: Double = 0.0
    @Published public private(set) var currentTranscription: String = ""
    
    // MARK: - Private Properties
    private var whisperKit: WhisperKit?
    private var selectedModel: String = "base"
    
    // MARK: - Model State
    public enum ModelState: Equatable {
        case notLoaded
        case loading
        case loaded(modelName: String)
        case failed(error: String)
    }
    
    // MARK: - Available Models
    public static let availableModels = [
        "tiny",
        "tiny.en",
        "base",
        "base.en",
        "small",
        "small.en",
        "medium",
        "medium.en",
        "large-v3",
        "distil-large-v3"
    ]
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Public Methods
    
    /// Initialize WhisperKit with the specified model
    /// - Parameter modelName: The name of the model to load (default: "base")
    public func initializeWhisperKit(modelName: String = "base") async {
        guard modelState != .loading else { return }
        
        modelState = .loading
        isLoading = true
        selectedModel = modelName
        
        do {
            // Initialize WhisperKit with the specified model
            whisperKit = try await WhisperKit(
                WhisperKitConfig(
                    model: modelName,
                    verbose: true,
                    logLevel: .debug,
                    prewarm: true
                )
            )
            modelState = .loaded(modelName: modelName)
            
            print("WhisperKit initialized successfully with model: \(modelName)")
        } catch {
            modelState = .failed(error: error.localizedDescription)
            print("Failed to initialize WhisperKit: \(error)")
        }
        
        isLoading = false
    }
    
    /// Initialize WhisperKit with a bundled model from the app bundle
    public func initializeWhisperKitWithBundledModel(
        modelName: String = "medium", 
        modelFolderName: String = "WhisperKitModels"
    ) async {
        guard modelState != .loading else { return }
        
        modelState = .loading
        isLoading = true
        selectedModel = modelName
        
        do {
            // Get the path to the bundled model folder
            guard let modelFolderURL = Bundle.main.url(
                forResource: modelFolderName, 
                withExtension: nil
            ) else {
                throw NSError(
                    domain: "WhisperKit", 
                    code: 404, 
                    userInfo: [NSLocalizedDescriptionKey: "Model folder not found"]
                )
            }
            
            // Construct the path to the specific model
            let modelPath = modelFolderURL.appendingPathComponent("openai_whisper-\(modelName)")
            
            // Initialize with bundled model
            whisperKit = try await WhisperKit(
                WhisperKitConfig(
                    model: modelName,
                    modelFolder: modelPath.path,
                    verbose: true,
                    logLevel: .debug,
                    prewarm: true,
                    load: true,
                    download: false  // Don't download when using bundled models
                )
            )
            modelState = .loaded(modelName: modelName)
            
            print("WhisperKit initialized successfully with bundled model: \(modelName)")
        } catch {
            modelState = .failed(error: error.localizedDescription)
            print("Failed to initialize WhisperKit with bundled model: \(error)")
        }
        
        isLoading = false
    }
    
    /// Transcribe audio from a file URL
    /// - Parameter audioURL: The URL of the audio file to transcribe
    /// - Returns: The transcribed text or nil if transcription fails
    public func transcribeAudio(from audioURL: URL) async -> String? {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not initialized")
            return nil
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        currentTranscription = ""
        
        do {
            // Transcribe the audio file
            let transcriptionResults = try await whisperKit.transcribe(
                audioPath: audioURL.path,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: "en",
                    temperature: 0.0,
                    temperatureFallbackCount: 5,
                    sampleLength: 224,
                    topK: 5,
                    usePrefillPrompt: true,
                    detectLanguage: true,
                    skipSpecialTokens: true,
                    withoutTimestamps: false
                ),
                callback: { progress in
                    // Update progress on main thread
                    DispatchQueue.main.async {
                        self.handleTranscriptionProgress(progress)
                    }
                    // Return true to continue processing
                    return true
                }
            )
            
            // Get the combined text from all results
            let fullText = transcriptionResults.map { $0.text }.joined(separator: " ")
            
            if !fullText.isEmpty {
                currentTranscription = fullText
                isTranscribing = false
                return fullText
            }
            
        } catch {
            print("Transcription error: \(error)")
            currentTranscription = "Transcription failed: \(error.localizedDescription)"
        }
        
        isTranscribing = false
        return nil
    }
    
    /// Transcribe audio from raw audio samples
    /// - Parameter audioSamples: Array of Float audio samples
    /// - Returns: The transcribed text or nil if transcription fails
    public func transcribeAudio(from audioSamples: [Float]) async -> String? {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not initialized")
            return nil
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        currentTranscription = ""
        
        do {
            // Transcribe the audio samples
            let transcriptionResults = try await whisperKit.transcribe(
                audioArray: audioSamples,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: "en",
                    temperature: 0.0,
                    temperatureFallbackCount: 5,
                    sampleLength: 224,
                    topK: 5,
                    usePrefillPrompt: true,
                    detectLanguage: true,
                    skipSpecialTokens: true,
                    withoutTimestamps: false
                ),
                callback: { progress in
                    // Update progress on main thread
                    DispatchQueue.main.async {
                        self.handleTranscriptionProgress(progress)
                    }
                    // Return true to continue processing
                    return true
                }
            )
            
            // Get the combined text from all results
            let fullText = transcriptionResults.map { $0.text }.joined(separator: " ")
            
            if !fullText.isEmpty {
                currentTranscription = fullText
                isTranscribing = false
                return fullText
            }
            
        } catch {
            print("Transcription error: \(error)")
            currentTranscription = "Transcription failed: \(error.localizedDescription)"
        }
        
        isTranscribing = false
        return nil
    }
    
    /// Change the WhisperKit model
    /// - Parameter newModel: The name of the new model to load
    public func changeModel(to newModel: String) async {
        // Deinitialize current model
        whisperKit = nil
        modelState = .notLoaded
        
        // Initialize with new model
        await initializeWhisperKit(modelName: newModel)
    }
    
    // MARK: - Private Methods
    
    private func handleTranscriptionProgress(_ progress: TranscriptionProgress) {
        // Update transcription progress
        let windowId = progress.windowId
        // Calculate progress based on window ID (this is an approximation)
        self.transcriptionProgress = min(Double(windowId) / 100.0, 1.0)
        
        // Update partial transcription if available
        let partialText = progress.text
        if !partialText.isEmpty {
            self.currentTranscription = partialText
        }
    }
}

// MARK: - TranscriptionResult Extension
public extension WhisperKitService {
    struct TranscriptionSegment {
        public let text: String
        public let startTime: Double
        public let endTime: Double
    }
    
    /// Get transcription with timestamps
    /// - Parameter audioURL: The URL of the audio file to transcribe
    /// - Returns: Array of transcription segments with timestamps
    func transcribeWithTimestamps(from audioURL: URL) async -> [TranscriptionSegment]? {
        guard let whisperKit = whisperKit else {
            print("WhisperKit not initialized")
            return nil
        }
        
        isTranscribing = true
        transcriptionProgress = 0.0
        currentTranscription = ""
        
        do {
            let transcriptionResults = try await whisperKit.transcribe(
                audioPath: audioURL.path,
                decodeOptions: DecodingOptions(
                    task: .transcribe,
                    language: "en",
                    withoutTimestamps: false
                )
            )
            
            var allSegments: [TranscriptionSegment] = []
            
            for result in transcriptionResults {
                let transcriptionSegments = result.segments.map { segment in
                    TranscriptionSegment(
                        text: segment.text,
                        startTime: Double(segment.start),
                        endTime: Double(segment.end)
                    )
                }
                allSegments.append(contentsOf: transcriptionSegments)
            }
            
            isTranscribing = false
            return allSegments.isEmpty ? nil : allSegments
            
        } catch {
            print("Transcription error: \(error)")
        }
        
        isTranscribing = false
        return nil
    }
} 