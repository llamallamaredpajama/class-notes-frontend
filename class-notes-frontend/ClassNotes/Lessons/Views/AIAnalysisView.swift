import SwiftUI

/// View displaying AI analysis results with editing capabilities
struct AIAnalysisView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let lesson: Lesson
    
    @State private var isEditing = false
    @State private var editedSummary = ""
    @State private var editedKeyPoints: [String] = []
    @State private var editedTopics: [String] = []
    @State private var editedQuestions: [String] = []
    @State private var showingGeneratePDF = false
    @State private var selectedTab: AnalysisTab = .summary
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Content
                TabView(selection: $selectedTab) {
                    summaryTab
                        .tag(AnalysisTab.summary)
                    
                    keyPointsTab
                        .tag(AnalysisTab.keyPoints)
                    
                    topicsTab
                        .tag(AnalysisTab.topics)
                    
                    questionsTab
                        .tag(AnalysisTab.questions)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Action button
                if !isEditing {
                    generatePDFButton
                        .padding()
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingGeneratePDF) {
                GeneratePDFView(lesson: lesson)
            }
            .onAppear {
                loadAnalysisData()
            }
        }
    }
    
    // MARK: - Views
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    private var summaryTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Label("Summary", systemImage: "doc.text")
                        .font(.headline)
                    
                    Text("AI-generated overview of your lesson")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Summary content
                if isEditing {
                    TextEditor(text: $editedSummary)
                        .font(.body)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .frame(minHeight: 300)
                } else {
                    Text(lesson.aiSummary ?? "No summary available")
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary.opacity(0.05))
                        )
                }
                
                // Word count
                HStack {
                    Image(systemName: "textformat.size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(wordCount(for: isEditing ? editedSummary : lesson.aiSummary ?? "")) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    private var keyPointsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Label("Key Points", systemImage: "star")
                        .font(.headline)
                    
                    Text("Important takeaways from your lesson")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Key points list
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        ForEach(editedKeyPoints.indices, id: \.self) { index in
                            EditableKeyPointRow(
                                text: $editedKeyPoints[index],
                                onDelete: {
                                    editedKeyPoints.remove(at: index)
                                }
                            )
                        }
                        
                        // Add new point button
                        Button {
                            editedKeyPoints.append("")
                        } label: {
                            Label("Add Key Point", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                        .padding(.top, 8)
                    } else {
                        ForEach(lesson.keyPoints ?? [], id: \.self) { point in
                            KeyPointRow(text: point)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var topicsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Label("Topics & Concepts", systemImage: "tag")
                        .font(.headline)
                    
                    Text("Main subjects covered in your lesson")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Topics grid
                if isEditing {
                    EditableTagsView(tags: $editedTopics)
                } else {
                    TagsView(tags: lesson.topics ?? [])
                }
            }
            .padding()
        }
    }
    
    private var questionsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Label("Study Questions", systemImage: "questionmark.bubble")
                        .font(.headline)
                    
                    Text("Practice questions to test your understanding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Questions list
                VStack(alignment: .leading, spacing: 16) {
                    if isEditing {
                        ForEach(editedQuestions.indices, id: \.self) { index in
                            EditableQuestionRow(
                                question: $editedQuestions[index],
                                number: index + 1,
                                onDelete: {
                                    editedQuestions.remove(at: index)
                                }
                            )
                        }
                        
                        // Add new question button
                        Button {
                            editedQuestions.append("")
                        } label: {
                            Label("Add Question", systemImage: "plus.circle")
                                .font(.subheadline)
                        }
                        .padding(.top, 8)
                    } else {
                        ForEach(Array((lesson.studyQuestions ?? []).enumerated()), id: \.offset) { index, question in
                            QuestionRow(question: question, number: index + 1)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var generatePDFButton: some View {
        Button {
            showingGeneratePDF = true
        } label: {
            Label("Generate PDF", systemImage: "doc.badge.arrow.up")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(isEditing ? "Save" : "Edit") {
                if isEditing {
                    saveChanges()
                } else {
                    startEditing()
                }
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Methods
    
    private func loadAnalysisData() {
        editedSummary = lesson.aiSummary ?? ""
        editedKeyPoints = lesson.keyPoints ?? []
        editedTopics = lesson.topics ?? []
        editedQuestions = lesson.studyQuestions ?? []
    }
    
    private func startEditing() {
        withAnimation {
            isEditing = true
        }
    }
    
    private func saveChanges() {
        lesson.aiSummary = editedSummary
        // TODO: Implement proper storage for keyPoints, topics, and studyQuestions
        // For now, just save the summary which is properly implemented
        
        do {
            try modelContext.save()
            withAnimation {
                isEditing = false
            }
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    private func wordCount(for text: String) -> Int {
        text.split(separator: " ").count
    }
}

// MARK: - Supporting Types

enum AnalysisTab: String, CaseIterable {
    case summary = "Summary"
    case keyPoints = "Key Points"
    case topics = "Topics"
    case questions = "Questions"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .summary: return "doc.text"
        case .keyPoints: return "star"
        case .topics: return "tag"
        case .questions: return "questionmark.bubble"
        }
    }
}

// MARK: - Supporting Views

struct KeyPointRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
        )
    }
}

struct EditableKeyPointRow: View {
    @Binding var text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            TextField("Enter key point", text: $text)
                .textFieldStyle(.roundedBorder)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct QuestionRow: View {
    let question: String
    let number: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 30, alignment: .trailing)
            
            Text(question)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.05))
        )
    }
}

struct EditableQuestionRow: View {
    @Binding var question: String
    let number: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number).")
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(width: 30, alignment: .trailing)
            
            TextField("Enter question", text: $question, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagChip(text: tag)
            }
        }
    }
}

struct EditableTagsView: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(tags.indices, id: \.self) { index in
                    EditableTagChip(
                        text: tags[index],
                        onDelete: {
                            tags.remove(at: index)
                        }
                    )
                }
            }
            
            HStack {
                TextField("Add topic", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    if !newTag.isEmpty {
                        tags.append(newTag)
                        newTag = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// Note: TagChip is defined earlier in this file

struct EditableTagChip: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.1))
        )
        .foregroundColor(.accentColor)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.replacingUnspecifiedDimensions().width, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for row in result.rows {
            for item in row {
                let x = bounds.minX + item.x
                let y = bounds.minY + item.y
                item.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
            }
        }
    }
    
    struct FlowResult {
        var rows: [[Item]] = []
        var height: CGFloat = 0
        
        struct Item {
            let subview: LayoutSubview
            let size: CGSize
            let x: CGFloat
            let y: CGFloat
        }
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentRow: [Item] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > width && !currentRow.isEmpty {
                    rows.append(currentRow)
                    currentRow = []
                    currentX = 0
                    currentY += rowHeight + spacing
                    rowHeight = 0
                }
                
                currentRow.append(Item(subview: subview, size: size, x: currentX, y: currentY))
                currentX += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
            
            if !currentRow.isEmpty {
                rows.append(currentRow)
                height = currentY + rowHeight
            }
        }
    }
}

// MARK: - Generate PDF View

struct GeneratePDFView: View {
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson
    
    @State private var includeTranscript = true
    @State private var includeSummary = true
    @State private var includeKeyPoints = true
    @State private var includeQuestions = true
    @State private var includeDrawings = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Include Transcript", isOn: $includeTranscript)
                    Toggle("Include Summary", isOn: $includeSummary)
                    Toggle("Include Key Points", isOn: $includeKeyPoints)
                    Toggle("Include Study Questions", isOn: $includeQuestions)
                    Toggle("Include Drawings", isOn: $includeDrawings)
                } header: {
                    Text("PDF Contents")
                } footer: {
                    Text("Select which sections to include in your PDF")
                }
                
                Section {
                    Button {
                        generatePDF()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Generate PDF", systemImage: "doc.badge.arrow.up")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Generate PDF")
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
    
    private func generatePDF() {
        // TODO: Implement PDF generation
        dismiss()
    }
}

// MARK: - Lesson Extensions

extension Lesson {
    var aiSummary: String? {
        get { summary }
        set { summary = newValue ?? "" }
    }
    
    var keyPoints: [String]? {
        // TODO: Implement key points storage
        return ["Key point 1", "Key point 2", "Key point 3"]
    }
    
    var topics: [String]? {
        // TODO: Implement topics storage
        return ["Mathematics", "Calculus", "Derivatives", "Integration"]
    }
    
    var studyQuestions: [String]? {
        // TODO: Implement study questions storage
        return [
            "What is the fundamental theorem of calculus?",
            "How do you find the derivative of a composite function?",
            "Explain the difference between definite and indefinite integrals."
        ]
    }
}

// MARK: - Preview

#Preview {
    let lesson = Lesson(
        title: "Calculus Lecture",
        date: Date(),
        duration: 3600,
        transcript: "Sample transcript"
    )
    
    return AIAnalysisView(lesson: lesson)
        .modelContainer(PersistenceController.preview.container)
} 