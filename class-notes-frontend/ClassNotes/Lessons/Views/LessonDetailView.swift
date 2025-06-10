import SwiftUI
import SwiftData

/// Detailed view for a lesson showing transcript, recording controls, and more
struct LessonDetailView: View {
    let lesson: Lesson
    @StateObject private var viewModel: LessonDetailViewModel
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var showingDrawingEditor = false
    @State private var showingDrawingsGallery = false
    
    init(lesson: Lesson) {
        self.lesson = lesson
        #if DEBUG
        self._viewModel = StateObject(wrappedValue: MockLessonDetailViewModel(lesson: lesson))
        #else
        // TODO: Initialize with real services when available
        self._viewModel = StateObject(wrappedValue: MockLessonDetailViewModel(lesson: lesson))
        #endif
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with lesson info
                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Lesson Title", text: $viewModel.editedTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                    
                    HStack {
                        if let course = lesson.course {
                            Label(course.name, systemImage: "folder")
                                .font(.caption)
                        }
                        
                        Label(lesson.formattedDuration, systemImage: "clock")
                            .font(.caption)
                        
                        Spacer()
                        
                        if lesson.hasAudio {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    // Tags
                    if !lesson.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(lesson.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Recording controls
                recordingControls
                
                // Transcript section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transcript")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $viewModel.editedTranscript)
                        .frame(minHeight: 300)
                        .padding(.horizontal)
                        .disabled(viewModel.isTranscribing)
                        .overlay(
                            Group {
                                if viewModel.isTranscribing {
                                    VStack {
                                        ProgressView()
                                        Text("Transcribing...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(.systemBackground).opacity(0.8))
                                }
                            }
                        )
                }
                
                // Drawings section
                drawingsSection
                
                // Action buttons
                actionButtons
            }
            .padding(.vertical)
        }
        .navigationTitle("Lesson Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        lesson.isFavorite.toggle()
                    } label: {
                        Label(lesson.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                              systemImage: lesson.isFavorite ? "star.fill" : "star")
                    }
                    
                    Button {
                        Task {
                            shareURL = await viewModel.shareLesson()
                            if shareURL != nil {
                                showingShareSheet = true
                            }
                        }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        // TODO: Implement delete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                // Clear error
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
    
    private var recordingControls: some View {
        VStack(spacing: 16) {
            // Recording status
            if viewModel.recordingState != .idle {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.red)
                        .symbolEffect(.pulse)
                    
                    Text(viewModel.recordingState == .transcribing ? "Transcribing..." : "Recording...")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(formatDuration(viewModel.recordingDuration))
                        .font(.system(.caption, design: .monospaced))
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Control buttons
            HStack(spacing: 20) {
                if viewModel.isRecording {
                    if viewModel.isPaused {
                        Button {
                            viewModel.resumeRecording()
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            viewModel.pauseRecording()
                        } label: {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button {
                        Task {
                            await viewModel.stopRecording()
                        }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button {
                        Task {
                            await viewModel.startRecording()
                        }
                    } label: {
                        Label("Start Recording", systemImage: "mic.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.recordingState == .transcribing)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var drawingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Drawings")
                    .font(.headline)
                
                Spacer()
                
                if !lesson.drawingCanvases.isEmpty {
                    Button {
                        showingDrawingsGallery = true
                    } label: {
                        Text("See All (\(lesson.drawingCanvases.count))")
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            
            if lesson.drawingCanvases.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "pencil.and.outline")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No drawings yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingDrawingEditor = true
                    } label: {
                        Label("Create Drawing", systemImage: "pencil.tip")
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                // Show recent drawings
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Add new drawing button
                        Button {
                            showingDrawingEditor = true
                        } label: {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 120, height: 90)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                
                                Text("New")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Recent drawings
                        ForEach(lesson.drawingCanvases.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3)) { canvas in
                            NavigationLink(destination: DrawingViewerView(lesson: lesson, canvas: canvas)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let thumbnailData = canvas.thumbnailData,
                                       let uiImage = UIImage(data: thumbnailData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 90)
                                            .clipped()
                                            .cornerRadius(8)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: canvas.backgroundColor) ?? .white)
                                            .frame(width: 120, height: 90)
                                            .overlay(
                                                Image(systemName: "pencil.tip.crop.circle")
                                                    .foregroundColor(.secondary)
                                            )
                                    }
                                    
                                    Text(canvas.title)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top)
        .sheet(isPresented: $showingDrawingEditor) {
            DrawingEditorView(lesson: lesson)
        }
        .navigationDestination(isPresented: $showingDrawingsGallery) {
            DrawingsGalleryView(lesson: lesson)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    try await viewModel.saveLesson()
                }
            } label: {
                Label("Save Changes", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)
            
            Button {
                Task {
                    shareURL = await viewModel.exportToPDF()
                    if shareURL != nil {
                        showingShareSheet = true
                    }
                }
            } label: {
                Label("Export to PDF", systemImage: "doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        if let sampleLesson = MockData.sampleLessons.first {
            LessonDetailView(lesson: sampleLesson)
        }
    }
    .modelContainer(PersistenceController.preview.container)
} 