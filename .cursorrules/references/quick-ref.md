# Quick Reference - Class Notes iOS/iPadOS

## Common Commands

### Development
```bash
# Open project in Xcode
open class-notes-frontend.xcodeproj

# Build from command line
xcodebuild -scheme ClassNotes -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -scheme ClassNotes -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Generate proto files
./Scripts/sync-protos.sh

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### SwiftLint
```bash
# Install SwiftLint
brew install swiftlint

# Run linter
swiftlint

# Auto-fix issues
swiftlint --fix
```

## Code Snippets

### SwiftUI View Template
```swift
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        content
            .navigationTitle("Feature")
            .toolbar { toolbarContent }
            .task { await viewModel.load() }
    }
    
    @ViewBuilder
    private var content: some View {
        // Main content
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
        }
    }
}
```

### View Model Template
```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published var error: AppError?
    
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol = Service.shared) {
        self.service = service
    }
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await service.fetchItems()
        } catch {
            self.error = AppError(error)
        }
    }
}
```

### gRPC Service Call
```swift
func fetchData() async throws -> Data {
    let request = DataRequest.with {
        $0.id = "123"
        $0.includeMetadata = true
    }
    
    let response = try await grpcClient.getData(request)
    return Data(from: response)
}
```

### Core Data Entity
```swift
extension CDLesson {
    func toModel() -> Lesson {
        Lesson(
            id: id ?? UUID().uuidString,
            title: title ?? "",
            subject: subject ?? "",
            date: date ?? Date(),
            documents: (documents as? Set<CDDocument>)?.map { $0.toModel() } ?? []
        )
    }
    
    func update(from model: Lesson) {
        self.id = model.id
        self.title = model.title
        self.subject = model.subject
        self.date = model.date
        self.lastModified = Date()
    }
}
```

## Common Patterns

### Async Image Loading
```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
    case .failure:
        Image(systemName: "photo")
            .foregroundStyle(.secondary)
    case .empty:
        ProgressView()
    @unknown default:
        EmptyView()
    }
}
```

### Alert Presentation
```swift
.alert("Error", isPresented: $showError, presenting: viewModel.error) { _ in
    Button("OK") { viewModel.error = nil }
} message: { error in
    Text(error.localizedDescription)
}
```

### Sheet Presentation
```swift
.sheet(isPresented: $showingDetails) {
    NavigationStack {
        DetailView()
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDetails = false }
                }
            }
    }
}
```

### Searchable List
```swift
NavigationStack {
    List(searchResults) { item in
        ItemRow(item: item)
    }
    .searchable(text: $searchText, prompt: "Search items...")
}

var searchResults: [Item] {
    if searchText.isEmpty {
        return items
    } else {
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}
```

## Environment Values

### Custom Environment Key
```swift
private struct APIClientKey: EnvironmentKey {
    static let defaultValue = APIClient.shared
}

extension EnvironmentValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

// Usage
@Environment(\.apiClient) var apiClient
```

## Testing Helpers

### Preview Provider
```swift
#Preview("Loading State") {
    LessonListView()
        .environmentObject(LessonViewModel(state: .loading))
}

#Preview("Error State") {
    LessonListView()
        .environmentObject(LessonViewModel(state: .error))
}
```

### Mock Data
```swift
extension Lesson {
    static let preview = Lesson(
        id: "preview-123",
        title: "Sample Lesson",
        subject: "Mathematics",
        date: Date(),
        documents: []
    )
    
    static let previewList = [
        preview,
        Lesson(id: "preview-456", title: "Physics Lesson", subject: "Physics", date: Date()),
        Lesson(id: "preview-789", title: "Chemistry Lab", subject: "Chemistry", date: Date())
    ]
}
```

## Debugging

### Print View Hierarchy
```bash
# In Xcode console
po UIApplication.shared.windows.first?.rootViewController
```

### Memory Graph
```
Product → Profile → Instruments → Leaks
```

### Network Debugging
```swift
// Enable gRPC logging
setenv("GRPC_TRACE", "all", 1)
setenv("GRPC_VERBOSITY", "debug", 1)
```

## Performance Tips

1. **Use `@StateObject` for view-owned objects**
2. **Use `@ObservedObject` for injected objects**
3. **Minimize `@Published` updates**
4. **Use `LazyVStack` for long lists**
5. **Profile with Instruments regularly**
6. **Avoid force unwrapping**
7. **Use `task` modifier for async work**
8. **Cache expensive computations**
9. **Debounce search queries**
10. **Preload critical resources**

## Common Gotchas

1. **`@MainActor` required for UI updates**
2. **`Task` cancellation needs handling**
3. **Core Data contexts are not thread-safe**
4. **SwiftUI previews need mock data**
5. **gRPC calls need error mapping**
6. **Keychain access can fail**
7. **Background tasks have time limits**
8. **Network calls need offline handling**
9. **Firebase tokens expire**
10. **Memory leaks in closures**

## Useful Extensions

### Date Formatting
```swift
extension Date {
    var shortFormat: String {
        formatted(date: .abbreviated, time: .shortened)
    }
    
    var relativeFormat: String {
        formatted(.relative(presentation: .named))
    }
}
```

### Collection Safety
```swift
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```

### View Modifiers
```swift
extension View {
    func errorAlert(error: Binding<AppError?>) -> some View {
        alert("Error", isPresented: .constant(error.wrappedValue != nil), presenting: error.wrappedValue) { _ in
            Button("OK") { error.wrappedValue = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
``` 