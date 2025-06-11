# UI/UX Patterns - SwiftUI Best Practices

## Overview

This document outlines UI/UX patterns and best practices for the Class Notes iOS/iPadOS application, focusing on SwiftUI implementations that provide excellent user experience across all Apple platforms.

## Design Principles

### 1. Platform-Adaptive Design
```swift
struct AdaptiveLayout: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad or large iPhone landscape
            HStack {
                sidebar
                detailView
            }
        } else {
            // iPhone portrait
            NavigationStack {
                sidebar
            }
        }
    }
}
```

### 2. Accessibility First
```swift
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus.circle.fill")
        }
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to perform action")
        .accessibilityAddTraits(.isButton)
    }
}
```

## Component Patterns

### Custom Navigation
```swift
struct CustomNavigationBar: View {
    let title: String
    @Binding var searchText: String
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and actions
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search lessons...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary, in: Capsule())
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
```

### Loading States
```swift
struct LoadingView<Content: View>: View {
    let isLoading: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            content()
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding(40)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}
```

### Empty States
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .bold()
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
```

### Error Handling UI
```swift
struct ErrorBanner: View {
    let error: AppError
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: error.icon)
                    .foregroundStyle(error.color)
                
                Text(error.title)
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(error.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let action = error.action {
                Button(action.title, action: action.handler)
                    .font(.footnote)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
```

## Animation Patterns

### Smooth Transitions
```swift
extension AnyTransition {
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// Usage
struct ContentView: View {
    @State private var showDetails = false
    
    var body: some View {
        VStack {
            if showDetails {
                DetailView()
                    .transition(.slideAndFade)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showDetails)
    }
}
```

### Interactive Gestures
```swift
struct SwipeableCard: View {
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    let onDelete: () -> Void
    
    var body: some View {
        content
            .offset(x: offset.width)
            .opacity(2 - Double(abs(offset.width / 50)))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        isDragging = true
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > 100 {
                            withAnimation(.spring()) {
                                offset = CGSize(width: value.translation.width > 0 ? 500 : -500, height: 0)
                            }
                            onDelete()
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                        isDragging = false
                    }
            )
    }
}
```

## iPad-Specific Patterns

### Split View
```swift
struct iPadSplitView: View {
    @State private var selectedLesson: Lesson?
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        NavigationSplitView {
            LessonListView(selection: $selectedLesson)
                .navigationSplitViewColumnWidth(min: 320, ideal: 400)
        } detail: {
            if let lesson = selectedLesson {
                LessonDetailView(lesson: lesson)
            } else {
                EmptyStateView(
                    icon: "doc.text",
                    title: "Select a Lesson",
                    message: "Choose a lesson from the sidebar to view its details",
                    actionTitle: nil,
                    action: nil
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

### Popover Presentations
```swift
struct PopoverExample: View {
    @State private var showingPopover = false
    
    var body: some View {
        Button("Show Options") {
            showingPopover = true
        }
        .popover(isPresented: $showingPopover) {
            OptionsView()
                .presentationCompactAdaptation(.sheet)
                .frame(idealWidth: 320, idealHeight: 400)
        }
    }
}
```

## Dark Mode Support

### Adaptive Colors
```swift
extension Color {
    static let adaptiveBackground = Color("AdaptiveBackground")
    static let adaptiveText = Color("AdaptiveText")
    
    // In Assets.xcassets, define colors with:
    // Light: #FFFFFF
    // Dark: #1C1C1E
}

struct ThemedView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Adaptive Content")
                .foregroundColor(.adaptiveText)
        }
        .background(Color.adaptiveBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
}
```

## Performance Considerations

### Lazy Loading
```swift
struct OptimizedList: View {
    let items: [Item]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items) { item in
                    ItemRow(item: item)
                        .onAppear {
                            // Prefetch next items if needed
                            if items.isLastItem(item) {
                                loadMoreItems()
                            }
                        }
                }
            }
            .padding()
        }
    }
}
```

### Image Optimization
```swift
struct OptimizedAsyncImage: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 100, height: 100)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .frame(width: 100, height: 100)
            @unknown default:
                EmptyView()
            }
        }
    }
}
```

## Common UI Components

### Custom Buttons
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) var isEnabled
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isEnabled ? Color.accentColor : Color.gray,
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .buttonStyle(.plain)
    }
}
```

### Form Components
```swift
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let prompt: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
```

## Best Practices Summary

1. **Always test on both iPhone and iPad** - Ensure layouts adapt properly
2. **Use semantic colors** - Support Dark Mode automatically
3. **Implement proper loading and error states** - Never leave users guessing
4. **Add haptic feedback** - Enhance user interactions
5. **Optimize for performance** - Use lazy loading and caching
6. **Follow Apple's Human Interface Guidelines** - Maintain platform consistency
7. **Test with Dynamic Type** - Support accessibility settings
8. **Implement keyboard avoidance** - Ensure forms are usable
9. **Add appropriate animations** - Make transitions smooth
10. **Consider offline states** - Show cached data when possible 