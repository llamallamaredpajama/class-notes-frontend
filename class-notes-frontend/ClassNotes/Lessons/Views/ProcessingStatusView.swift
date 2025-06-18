import SwiftUI

/// View displaying the processing status for AI analysis
struct ProcessingStatusView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let lesson: Lesson
    
    @State private var currentStep: ProcessingStep = .uploading
    @State private var progress: Double = 0
    @State private var estimatedTimeRemaining: TimeInterval = 120
    @State private var showingCancelConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var startTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    // Progress indicator
                    progressSection
                    
                    // Steps list
                    stepsSection
                    
                    // Time estimate
                    timeSection
                    
                    // Cancel button
                    if currentStep != .completed && currentStep != .failed {
                        cancelButton
                    }
                    
                    // Error recovery
                    if currentStep == .failed {
                        errorRecoverySection
                    }
                    
                    // Success actions
                    if currentStep == .completed {
                        successActionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Processing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep == .completed || currentStep == .failed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog("Cancel Processing?", isPresented: $showingCancelConfirmation) {
                Button("Cancel Processing", role: .destructive) {
                    cancelProcessing()
                }
                Button("Continue", role: .cancel) {}
            } message: {
                Text("This will stop the AI processing. You can restart it later.")
            }
            .alert("Processing Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onReceive(timer) { _ in
                updateProgress()
            }
            .task {
                await startProcessing()
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(currentStep.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: currentStep.icon)
                    .font(.system(size: 50))
                    .foregroundColor(currentStep.color)
                    .symbolEffect(.variableColor.iterative, value: currentStep)
            }
            
            Text(currentStep.title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(currentStep.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(currentStep.color)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Percentage
            Text("\(Int(progress * 100))%")
                .font(.headline)
                .foregroundColor(currentStep.color)
        }
        .padding(.horizontal)
    }
    
    private var stepsSection: some View {
        VStack(spacing: 16) {
            ForEach(ProcessingStep.allCases, id: \.self) { step in
                ProcessingStepRow(
                    step: step,
                    currentStep: currentStep,
                    isCompleted: step.rawValue < currentStep.rawValue
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.05))
        )
    }
    
    @ViewBuilder
    private var timeSection: some View {
        if currentStep != .completed && currentStep != .failed {
            VStack(spacing: 8) {
                Label("Estimated time remaining", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatTime(estimatedTimeRemaining))
                    .font(.title3)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        } else if currentStep == .completed {
            VStack(spacing: 8) {
                Label("Total processing time", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text(formatTime(Date().timeIntervalSince(startTime)))
                    .font(.title3)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
        }
    }
    
    private var cancelButton: some View {
        Button {
            showingCancelConfirmation = true
        } label: {
            Label("Cancel Processing", systemImage: "xmark.circle")
                .foregroundColor(.red)
        }
        .buttonStyle(.bordered)
    }
    
    private var errorRecoverySection: some View {
        VStack(spacing: 16) {
            // Error message
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                
                Text("Processing Failed")
                    .font(.headline)
                
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
            
            // Recovery options
            VStack(spacing: 12) {
                Button {
                    Task {
                        await retryProcessing()
                    }
                } label: {
                    Label("Retry Processing", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    dismiss()
                } label: {
                    Text("Try Again Later")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private var successActionsSection: some View {
        VStack(spacing: 16) {
            // Success message
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .symbolEffect(.bounce)
                
                Text("Processing Complete!")
                    .font(.headline)
                
                Text("Your lesson has been analyzed and is ready to view")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                NavigationLink(destination: AIAnalysisView(lesson: lesson)) {
                    Label("View Analysis", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink(destination: PDFViewerView(lesson: lesson)) {
                    Label("View PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Methods
    
    private func startProcessing() async {
        // Simulate processing steps
        for step in ProcessingStep.allCases {
            if step == .completed || step == .failed {
                continue
            }
            
            currentStep = step
            
            // Simulate processing time for each step
            let duration = step.estimatedDuration
            let increments = 20
            let incrementDuration = duration / Double(increments)
            
            for i in 0..<increments {
                try? await Task.sleep(nanoseconds: UInt64(incrementDuration * 1_000_000_000))
                
                await MainActor.run {
                    progress = (Double(step.rawValue) + Double(i) / Double(increments)) / Double(ProcessingStep.allCases.count - 2)
                }
            }
        }
        
        // Mark as completed
        await MainActor.run {
            currentStep = .completed
            progress = 1.0
            lesson.processingStatus = .completed
            try? modelContext.save()
        }
    }
    
    private func updateProgress() {
        if currentStep != .completed && currentStep != .failed {
            estimatedTimeRemaining = max(0, estimatedTimeRemaining - 1)
        }
    }
    
    private func cancelProcessing() {
        currentStep = .failed
        errorMessage = "Processing was cancelled by user"
        lesson.processingStatus = .failed
        try? modelContext.save()
    }
    
    private func retryProcessing() async {
        currentStep = .uploading
        progress = 0
        errorMessage = ""
        showingError = false
        startTime = Date()
        estimatedTimeRemaining = 120
        
        await startProcessing()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Supporting Types

enum ProcessingStep: Int, CaseIterable {
    case uploading = 0
    case transcribing = 1
    case analyzing = 2
    case generating = 3
    case finalizing = 4
    case completed = 5
    case failed = 6
    
    var title: String {
        switch self {
        case .uploading: return "Uploading Content"
        case .transcribing: return "Transcribing Audio"
        case .analyzing: return "Analyzing Content"
        case .generating: return "Generating PDF"
        case .finalizing: return "Finalizing"
        case .completed: return "Complete!"
        case .failed: return "Processing Failed"
        }
    }
    
    var description: String {
        switch self {
        case .uploading: return "Uploading your lesson to the cloud"
        case .transcribing: return "Converting audio to text using AI"
        case .analyzing: return "Understanding and summarizing content"
        case .generating: return "Creating your formatted PDF"
        case .finalizing: return "Saving and preparing for viewing"
        case .completed: return "Your lesson is ready!"
        case .failed: return "Something went wrong"
        }
    }
    
    var icon: String {
        switch self {
        case .uploading: return "icloud.and.arrow.up"
        case .transcribing: return "waveform"
        case .analyzing: return "brain"
        case .generating: return "doc.text"
        case .finalizing: return "checkmark.seal"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .uploading: return .blue
        case .transcribing: return .purple
        case .analyzing: return .orange
        case .generating: return .indigo
        case .finalizing: return .teal
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var estimatedDuration: TimeInterval {
        switch self {
        case .uploading: return 5
        case .transcribing: return 30
        case .analyzing: return 20
        case .generating: return 15
        case .finalizing: return 5
        case .completed, .failed: return 0
        }
    }
}

// MARK: - Processing Step Row

struct ProcessingStepRow: View {
    let step: ProcessingStep
    let currentStep: ProcessingStep
    let isCompleted: Bool
    
    private var isActive: Bool {
        step == currentStep
    }
    
    private var isFuture: Bool {
        step.rawValue > currentStep.rawValue && currentStep != .failed
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(stepColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(stepColor)
                } else if isActive {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: stepColor))
                        .scaleEffect(0.7)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(stepColor)
                }
            }
            
            // Step info
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .medium)
                    .foregroundColor(isFuture ? .secondary : .primary)
                
                if isActive {
                    Text(step.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else if isActive {
                Text("Processing...")
                    .font(.caption)
                    .foregroundColor(stepColor)
            }
        }
        .opacity(isFuture ? 0.5 : 1.0)
    }
    
    private var stepColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return step.color
        } else {
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    let lesson = Lesson(
        title: "Sample Lesson",
        date: Date(),
        duration: 0,
        transcript: ""
    )
    return ProcessingStatusView(lesson: lesson)
        .modelContainer(PersistenceController.preview.container)
} 