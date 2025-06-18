import SwiftUI
import AVFoundation

/// Main recording interface for capturing audio
struct RecordingView: View {
    // MARK: - Properties
    
    let lessonTitle: String
    let course: Course?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audioRecorder = AudioRecorder()
    
    @State private var isRecording = false
    @State private var isPaused = false
    @State private var showingStopConfirmation = false
    @State private var showingDiscardConfirmation = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var waveformLevels: [CGFloat] = Array(repeating: 0.5, count: 50)
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.black.opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    waveformSection
                        .frame(height: 200)
                    
                    Spacer()
                    
                    controlsSection
                        .padding(.bottom, 40)
                }
                .padding(.horizontal)
            }
            .navigationBarHidden(true)
            .onReceive(timer) { _ in
                if isRecording && !isPaused {
                    recordingDuration += 0.1
                    updateWaveform()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .alert("Stop Recording?", isPresented: $showingStopConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Stop & Save", role: .destructive) {
                    stopAndSaveRecording()
                }
            } message: {
                Text("This will end the recording and save your lesson.")
            }
            .alert("Discard Recording?", isPresented: $showingDiscardConfirmation) {
                Button("Keep Recording", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    discardRecording()
                }
            } message: {
                Text("Are you sure you want to discard this recording? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Button {
                    if isRecording {
                        showingDiscardConfirmation = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Recording indicator
                if isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .opacity(isPaused ? 0.5 : 1.0)
                            .scaleEffect(isPaused ? 1.0 : 1.2)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording && !isPaused)
                        
                        Text(isPaused ? "PAUSED" : "RECORDING")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.3))
                    )
                }
            }
            
            // Title and course
            VStack(spacing: 8) {
                Text(lessonTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let course = course {
                    HStack {
                        Image(systemName: course.icon)
                        Text(course.name)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Duration counter
            Text(formatDuration(recordingDuration))
                .font(.system(size: 48, weight: .thin, design: .monospaced))
                .foregroundColor(.white)
                .padding(.top, 20)
        }
    }
    
    private var waveformSection: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<waveformLevels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.8),
                                    Color.accentColor
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: (geometry.size.width - CGFloat(waveformLevels.count - 1) * 2) / CGFloat(waveformLevels.count))
                        .scaleEffect(x: 1, y: waveformLevels[index], anchor: .center)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: waveformLevels[index])
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 32) {
            // Main recording button
            Button {
                if isRecording {
                    if isPaused {
                        resumeRecording()
                    } else {
                        pauseRecording()
                    }
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isRecording ? (isPaused ? Color.orange : Color.red) : Color.accentColor)
                        .frame(width: 100, height: 100)
                    
                    if isRecording {
                        if isPaused {
                            Image(systemName: "play.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                        }
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
            }
            .scaleEffect(isRecording && !isPaused ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording && !isPaused)
            
            // Secondary controls
            if isRecording {
                HStack(spacing: 60) {
                    // Discard button
                    Button {
                        showingDiscardConfirmation = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Discard")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Stop button
                    Button {
                        showingStopConfirmation = true
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .stroke(Color.green, lineWidth: 3)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                            
                            Text("Stop")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            } else {
                // Helpful hint
                Text("Tap to start recording")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func updateWaveform() {
        // Simulate waveform with random values
        // In production, this would use actual audio levels from AVAudioRecorder
        let newLevel = CGFloat.random(in: 0.2...1.0)
        
        // Shift all levels to the left
        for i in 0..<waveformLevels.count - 1 {
            waveformLevels[i] = waveformLevels[i + 1]
        }
        
        // Add new level at the end
        waveformLevels[waveformLevels.count - 1] = newLevel
    }
    
    private func startRecording() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isRecording = true
            isPaused = false
        }
        
        // Configure audio session for recording
        configureAudioSession()
        
        // Start actual recording
        audioRecorder.startRecording()
    }
    
    private func pauseRecording() {
        withAnimation {
            isPaused = true
        }
        audioRecorder.pauseRecording()
    }
    
    private func resumeRecording() {
        withAnimation {
            isPaused = false
        }
        audioRecorder.resumeRecording()
    }
    
    private func stopAndSaveRecording() {
        audioRecorder.stopRecording()
        
        // Create lesson object
        let lesson = Lesson(
            title: lessonTitle
        )
        lesson.duration = Int(recordingDuration)
        lesson.hasAudio = true
        lesson.processingStatus = ProcessingStatus.processing
        
        // Save to Core Data
        modelContext.insert(lesson)
        
        // Dismiss and navigate to transcription view
        dismiss()
        
        // Navigation to transcription will be handled by the parent view
        // by observing the lesson's processingStatus
    }
    
    private func discardRecording() {
        audioRecorder.stopRecording()
        audioRecorder.deleteRecording()
        dismiss()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Continue recording in background
            if isRecording && !isPaused {
                audioRecorder.enableBackgroundRecording()
            }
        case .active:
            // Resume UI updates
            if isRecording {
                audioRecorder.disableBackgroundRecording()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Audio Recorder

@MainActor
class AudioRecorder: ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    func startRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = documentsPath.appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
    }
    
    func deleteRecording() {
        audioRecorder?.stop()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func enableBackgroundRecording() {
        // Background recording configuration
    }
    
    func disableBackgroundRecording() {
        // Resume foreground recording
    }
}

// MARK: - Preview

#Preview {
    RecordingView(
        lessonTitle: "Introduction to SwiftUI",
        course: Course(name: "iOS Development", icon: "apple.logo")
    )
} 