import SwiftUI

/// Updated LessonListView using gRPC-Swift v2 ViewModel
struct LessonListViewV2: View {
    @StateObject private var viewModel = LessonListViewModelV2()
    @State private var showingCreateSheet = false
    @State private var newLessonTitle = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredLessons) { lesson in
                    NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                        LessonRowView(lesson: lesson)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.deleteLesson(viewModel.filteredLessons[index])
                        }
                    }
                }
                
                // Load more button when pagination is available
                if viewModel.hasMorePages && !viewModel.isLoading {
                    Button(action: {
                        Task {
                            await viewModel.loadMoreLessons()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Load More")
                                .foregroundColor(.accentColor)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search lessons")
            .navigationTitle("Lessons")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOrder) {
                            ForEach(LessonListViewModelV2.SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Label("New Lesson", systemImage: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshLessons()
            }
            .task {
                await viewModel.loadLessons()
            }
            .overlay {
                if viewModel.isLoading && viewModel.lessons.isEmpty {
                    ProgressView("Loading lessons...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateLessonSheet(title: $newLessonTitle) { title in
                    Task {
                        _ = await viewModel.createLesson(title: title)
                        showingCreateSheet = false
                        newLessonTitle = ""
                    }
                }
            }
        }
    }
}

// MARK: - Lesson Row View

struct LessonRowView: View {
    let lesson: Lesson
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Label(lesson.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if lesson.duration > 0 {
                    Label(formatDuration(lesson.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let summary = lesson.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

// MARK: - Create Lesson Sheet

struct CreateLessonSheet: View {
    @Binding var title: String
    let onCreate: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Lesson Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .navigationTitle("New Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(title)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LessonListViewV2_Previews: PreviewProvider {
    static var previews: some View {
        LessonListViewV2()
    }
}
#endif 