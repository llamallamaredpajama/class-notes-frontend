import SwiftUI
import AVFoundation

/// Example view demonstrating WhisperKit integration for audio recording and transcription
struct WhisperKitExampleView: View {
    @StateObject private var whisperService = WhisperKitService()
    @StateObject private var audioRecorder = WhisperKitAudioRecorder()
    
    @State private var selectedModel = "medium"  // Using pre-bundled medium model
    @State private var showingModelPicker = false
    @State private var transcribedText = ""
    @State private var isRecording = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Model Selection
                modelSelectionSection
                
                // Recording Controls
                recordingSection
                
                // Transcription Display
                transcriptionSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("WhisperKit Demo")
            .task {
                // Use bundled model (medium is pre-bundled)
                await whisperService.initializeWhisperKitWithBundledModel(modelName: "medium")
            }
            .sheet(isPresented: $showingModelPicker) {
                modelPickerSheet
            }
        }
    }
    
    // MARK: - View Components
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Model Selection")
                .font(.headline)
            
            HStack {
                Text("Current Model:")
                    .foregroundColor(.secondary)
                
                switch whisperService.modelState {
                case .notLoaded:
                    Text("Not Loaded")
                        .foregroundColor(.red)
                case .loading:
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                    }
                case .loaded(let modelName):
                    Text(modelName)
                        .foregroundColor(.green)
                case .failed(let error):
                    Text("Failed: \(error)")
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button("Change") {
                    showingModelPicker = true
                }
                .disabled(whisperService.isLoading)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var recordingSection: some View {
        VStack(spacing: 15) {
            Text("Audio Recording")
                .font(.headline)
            
            // Recording Button
            Button(action: toggleRecording) {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(isRecording ? .red : .blue)
                    
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
            }
            .disabled(whisperService.modelState != .loaded(modelName: selectedModel))
            
            if isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                    Text("Recording...")
                        .foregroundColor(.red)
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                }
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: isRecording)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Transcription")
                    .font(.headline)
                
                Spacer()
                
                if whisperService.isTranscribing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("\(Int(whisperService.transcriptionProgress * 100))%")
                            .font(.caption)
                    }
                }
            }
            
            ScrollView {
                Text(transcribedText.isEmpty ? "Transcribed text will appear here..." : transcribedText)
                    .foregroundColor(transcribedText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(minHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if !transcribedText.isEmpty {
                Button(action: copyToClipboard) {
                    Label("Copy to Clipboard", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var modelPickerSheet: some View {
        NavigationView {
            List(WhisperKitService.availableModels, id: \.self) { model in
                HStack {
                    Text(model)
                    Spacer()
                    if model == selectedModel {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Task {
                        selectedModel = model
                        showingModelPicker = false
                        await whisperService.changeModel(to: model)
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarItems(trailing: Button("Cancel") {
                showingModelPicker = false
            })
        }
    }
    
    // MARK: - Actions
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            do {
                try await audioRecorder.startRecording()
                isRecording = true
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    private func stopRecording() {
        Task {
            let audioURL = await audioRecorder.stopRecording()
            isRecording = false
            
            if let url = audioURL {
                transcribedText = await whisperService.transcribeAudio(from: url) ?? "Transcription failed"
            }
        }
    }
    
    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = transcribedText
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcribedText, forType: .string)
        #endif
    }
}

// MARK: - Audio Recorder

/// Simple audio recorder for demonstration purposes
@MainActor
class WhisperKitAudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    func startRecording() async throws {
        let session = AVAudioSession.sharedInstance()
        
        #if os(iOS)
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)
        #endif
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        recordingURL = audioFilename
        
        audioRecorder?.record()
    }
    
    func stopRecording() async -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        
        return recordingURL
    }
}

// MARK: - Preview

struct WhisperKitExampleView_Previews: PreviewProvider {
    static var previews: some View {
        WhisperKitExampleView()
    }
} 