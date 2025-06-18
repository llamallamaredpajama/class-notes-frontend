import SwiftUI

/// View for displaying and editing transcription results
struct TranscriptionView: View {
    // MARK: - Properties
    
    let lesson: Lesson
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var transcriptText = ""
    @State private var isProcessing = true
    @State private var showingExportOptions = false
    @State private var confidenceLevel: Double = 0.95
    @State private var selectedExportFormat: ExportFormat = .pdf
    
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isProcessing {
                    processingView
                } else {
                    transcriptionContent
                }
            }
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView(
                    lesson: lesson,
                    selectedFormat: $selectedExportFormat
                )
            }
            .task {
                await startTranscription()
            }
        }
    }
    
    // MARK: - Views
    
    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated icon
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .symbolEffect(.variableColor.iterative)
            
            Text("Transcribing Audio...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This may take a few moments")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding(.top)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private var transcriptionContent: some View {
        VStack(spacing: 0) {
            // Confidence indicator
            confidenceIndicator
                .padding()
            
            Divider()
            
            // Transcription text
            ScrollView {
                TextEditor(text: $transcriptText)
                    .focused($isTextFieldFocused)
                    .font(.body)
                    .padding()
                    .frame(minHeight: 300)
                    .background(Color.clear)
            }
            
            Divider()
            
            // Action buttons
            actionButtons
                .padding()
        }
    }
    
    private var confidenceIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Transcription Confidence", systemImage: "checkmark.shield")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(confidenceLevel * 100))%")
                    .font(.headline)
                    .foregroundColor(confidenceColor)
            }
            
            ProgressView(value: confidenceLevel)
                .tint(confidenceColor)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("High confidence in transcription accuracy")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Speaker diarization (if available)
            Button {
                // TODO: Show speaker diarization
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "person.2.circle")
                        .font(.title2)
                    Text("Speakers")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .disabled(true) // Enable based on tier
            
            // Edit/Format
            Button {
                isTextFieldFocused = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "pencil.circle")
                        .font(.title2)
                    Text("Edit")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            
            // Export options
            Button {
                showingExportOptions = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up.circle")
                        .font(.title2)
                    Text("Export")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.1))
                )
            }
        }
        .foregroundColor(.primary)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
                saveTranscription()
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Computed Properties
    
    private var confidenceColor: Color {
        switch confidenceLevel {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return .orange
        default:
            return .red
        }
    }
    
    // MARK: - Methods
    
    private func startTranscription() async {
        // Simulate transcription process
        isProcessing = true
        
        // TODO: Integrate with WhisperKit for actual transcription
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Set sample transcription
        withAnimation {
            transcriptText = """
            Welcome to today's lecture on SwiftUI fundamentals. 
            
            We'll be covering the following topics:
            1. Understanding the declarative syntax
            2. Working with state management
            3. Building responsive layouts
            4. Animation and transitions
            
            Let's start with the basics of SwiftUI's declarative approach...
            """
            
            isProcessing = false
        }
    }
    
    private func saveTranscription() {
        lesson.transcript = transcriptText
        lesson.processingStatus = .completed
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save transcription: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum ExportFormat {
    case pdf
    case txt
    case docx
}

// MARK: - Export Options View

struct ExportOptionsView: View {
    let lesson: Lesson
    @Binding var selectedFormat: ExportFormat
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export Transcription")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    FormatOption(
                        format: .pdf,
                        title: "PDF Document",
                        description: "Formatted document with styling",
                        icon: "doc.fill",
                        isSelected: selectedFormat == .pdf,
                        action: { selectedFormat = .pdf }
                    )
                    
                    FormatOption(
                        format: .txt,
                        title: "Plain Text",
                        description: "Simple text file",
                        icon: "doc.text",
                        isSelected: selectedFormat == .txt,
                        action: { selectedFormat = .txt }
                    )
                    
                    FormatOption(
                        format: .docx,
                        title: "Word Document",
                        description: "Microsoft Word format",
                        icon: "doc.richtext",
                        isSelected: selectedFormat == .docx,
                        action: { selectedFormat = .docx }
                    )
                }
                .padding()
                
                Spacer()
                
                Button {
                    exportTranscription()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportTranscription() {
        // TODO: Implement export functionality
        dismiss()
    }
}

struct FormatOption: View {
    let format: ExportFormat
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    let lesson = Lesson(
        title: "Introduction to SwiftUI",
        date: Date(),
        duration: 3600,
        transcript: ""
    )
    return TranscriptionView(lesson: lesson)
        .modelContainer(PersistenceController.preview.container)
} 