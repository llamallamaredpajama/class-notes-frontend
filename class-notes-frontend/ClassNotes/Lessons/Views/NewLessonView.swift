import SwiftUI
import SwiftData
import AVFoundation

/// View for creating a new lesson
struct NewLessonView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    
    @State private var lessonTitle = ""
    @State private var selectedCourse: Course?
    @State private var showingCourseCreation = false
    @State private var showingMicrophonePermissionAlert = false
    @State private var microphonePermissionStatus: AVAudioSession.RecordPermission = .undetermined
    
    @FocusState private var titleFieldFocused: Bool
    
    private var isFormValid: Bool {
        !lessonTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Permission Status Helpers
    
    private var isPermissionGranted: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return microphonePermissionStatus == .granted
        }
    }
    
    private var isPermissionUndetermined: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .undetermined
        } else {
            return microphonePermissionStatus == .undetermined
        }
    }
    
    private var suggestedTitles: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        let today = dateFormatter.string(from: Date())
        
        let coursePrefix = selectedCourse?.name ?? "Class"
        
        return [
            "\(coursePrefix) - \(today)",
            "\(coursePrefix) Lecture Notes",
            "\(coursePrefix) Discussion",
            "\(coursePrefix) Lab Session",
            "\(coursePrefix) Review Session"
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    titleSection
                    courseSection
                    preRecordingChecklist
                    
                    Spacer(minLength: 40)
                    
                    startRecordingButton
                }
                .padding()
            }
            .navigationTitle("New Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCourseCreation) {
                CreateCourseView()
            }
            .alert("Microphone Access Required", isPresented: $showingMicrophonePermissionAlert) {
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please allow microphone access in Settings to record lessons.")
            }
            .task {
                await checkMicrophonePermission()
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .symbolEffect(.pulse)
            
            Text("Let's capture your learning")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Set up your lesson details before recording")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Lesson Title", systemImage: "textformat")
                .font(.headline)
            
            TextField("Enter lesson title", text: $lessonTitle)
                .textFieldStyle(.roundedBorder)
                .focused($titleFieldFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        titleFieldFocused = true
                    }
                }
            
            // Title suggestions
            if lessonTitle.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(suggestedTitles.prefix(3), id: \.self) { suggestion in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                lessonTitle = suggestion
                            }
                        } label: {
                            HStack {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var courseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Course (Optional)", systemImage: "folder")
                .font(.headline)
            
            HStack {
                Menu {
                    ForEach(courses) { course in
                        Button {
                            selectedCourse = course
                        } label: {
                            Label(course.name, systemImage: course.icon)
                        }
                    }
                    
                    if !courses.isEmpty {
                        Divider()
                    }
                    
                    Button {
                        selectedCourse = nil
                    } label: {
                        Label("No Course", systemImage: "minus.circle")
                    }
                } label: {
                    HStack {
                        if let course = selectedCourse {
                            Image(systemName: course.icon)
                                .foregroundColor(course.courseColor.swiftUIColor)
                            Text(course.name)
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "folder")
                                .foregroundColor(.secondary)
                            Text("Select a course")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                }
                
                Button {
                    showingCourseCreation = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private var preRecordingChecklist: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Pre-Recording Checklist", systemImage: "checklist")
                .font(.headline)
            
            VStack(spacing: 12) {
                ChecklistItem(
                    icon: "mic",
                    title: "Microphone Ready",
                    description: "Ensure you're in a quiet environment",
                    isChecked: isPermissionGranted
                )
                
                ChecklistItem(
                    icon: "battery.100",
                    title: "Battery Charged",
                    description: "Recording can use significant battery",
                    isChecked: UIDevice.current.batteryLevel > 0.2
                )
                
                ChecklistItem(
                    icon: "internaldrive",
                    title: "Storage Available",
                    description: "At least 100MB free space recommended",
                    isChecked: true // TODO: Check actual storage
                )
                
                ChecklistItem(
                    icon: "airplane.slash",
                    title: "Airplane Mode Off",
                    description: "For cloud sync after recording",
                    isChecked: true // TODO: Check actual status
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.05))
            )
        }
    }
    
    private var startRecordingButton: some View {
        NavigationLink(destination: RecordingView(
            lessonTitle: lessonTitle,
            course: selectedCourse
        )) {
            HStack {
                Image(systemName: "mic.fill")
                Text("Start Recording")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid ? Color.accentColor : Color.gray)
            )
        }
        .disabled(!isFormValid || !isPermissionGranted)
    }
    
    // MARK: - Methods
    
    private func checkMicrophonePermission() async {
        if #available(iOS 17.0, *) {
            // iOS 17+: Use AVAudioApplication
            let currentPermission = AVAudioApplication.shared.recordPermission
            
            if currentPermission == .undetermined {
                let granted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                // Update the legacy state variable for UI consistency
                microphonePermissionStatus = granted ? .granted : .denied
            } else {
                // Convert AVAudioApplication.RecordPermission to AVAudioSession.RecordPermission for UI
                switch currentPermission {
                case .granted:
                    microphonePermissionStatus = .granted
                case .denied:
                    microphonePermissionStatus = .denied
                @unknown default:
                    microphonePermissionStatus = .undetermined
                }
            }
            
            if AVAudioApplication.shared.recordPermission == .denied {
                showingMicrophonePermissionAlert = true
            }
        } else {
            // iOS 16 and earlier: Use AVAudioSession
            microphonePermissionStatus = AVAudioSession.sharedInstance().recordPermission
            
            if microphonePermissionStatus == .undetermined {
                let granted = await withCheckedContinuation { continuation in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                microphonePermissionStatus = granted ? .granted : .denied
            }
            
            if microphonePermissionStatus == .denied {
                showingMicrophonePermissionAlert = true
            }
        }
    }
}

// MARK: - Supporting Views

struct ChecklistItem: View {
    let icon: String
    let title: String
    let description: String
    let isChecked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isChecked ? "\(icon).fill" : icon)
                .font(.title2)
                .foregroundColor(isChecked ? .green : .secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isChecked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}

struct CreateCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var courseName = ""
    @State private var selectedIcon = "book.fill"
    @State private var selectedColor = CourseColor.blue
    
    private let iconOptions = [
        "book.fill", "graduationcap.fill", "pencil", "folder.fill",
        "doc.text.fill", "laptopcomputer", "brain", "lightbulb.fill",
        "atom", "function", "globe", "leaf.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Course Name", text: $courseName)
                } header: {
                    Text("Course Details")
                }
                
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedIcon == icon ? selectedColor.swiftUIColor : Color.secondary.opacity(0.1))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Icon")
                }
                
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(CourseColor.allCases, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(color.swiftUIColor)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                            .padding(2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                }
            }
            .navigationTitle("New Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createCourse()
                    }
                    .disabled(courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createCourse() {
        let course = Course(
            name: courseName.trimmingCharacters(in: .whitespacesAndNewlines),
            color: selectedColor,
            icon: selectedIcon
        )
        modelContext.insert(course)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NewLessonView()
        .modelContainer(PersistenceController.preview.container)
} 