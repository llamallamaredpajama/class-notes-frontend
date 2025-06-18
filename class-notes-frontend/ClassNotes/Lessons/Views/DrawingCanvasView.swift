import SwiftUI
import PencilKit

/// Enhanced drawing canvas with full PencilKit features
struct DrawingCanvasView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var canvasView = PKCanvasView()
    @State private var isToolPickerActive = true
    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: Color = .black
    @State private var lineWidth: CGFloat = 2.0
    @State private var showingColorPicker = false
    @State private var showingBackgroundOptions = false
    @State private var backgroundType: BackgroundType = .blank
    @State private var showingClearConfirmation = false
    @State private var isDrawingModified = false
    
    let lesson: Lesson?
    let drawingCanvas: DrawingCanvas?
    let onSave: ((PKDrawing) -> Void)?
    
    // Academic color presets
    private let academicColors: [Color] = [
        .black, .blue, .red, .green, .orange, .purple,
        .pink, .brown, .indigo, .mint, .cyan, .yellow
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView
                
                // Drawing canvas
                PencilKitCanvas(
                    canvasView: $canvasView,
                    isToolPickerActive: $isToolPickerActive,
                    selectedTool: selectedTool,
                    selectedColor: selectedColor,
                    lineWidth: lineWidth,
                    onDrawingChanged: { isDrawingModified = true }
                )
                .ignoresSafeArea(.container, edges: .bottom)
                
                // Custom tool palette
                VStack {
                    Spacer()
                    
                    if !isToolPickerActive {
                        customToolPalette
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(drawingCanvas?.title ?? "New Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedColor)
            }
            .sheet(isPresented: $showingBackgroundOptions) {
                BackgroundOptionsView(selectedBackground: $backgroundType)
            }
            .confirmationDialog("Clear Canvas?", isPresented: $showingClearConfirmation) {
                Button("Clear", role: .destructive) {
                    clearCanvas()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all drawings. This action cannot be undone.")
            }
            .interactiveDismissDisabled(isDrawingModified)
            .onAppear {
                setupCanvas()
            }
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var backgroundView: some View {
        switch backgroundType {
        case .blank:
            Color(.systemBackground)
        case .grid:
            GridBackgroundView()
        case .ruled:
            RuledBackgroundView()
        case .dotted:
            DottedBackgroundView()
        }
    }
    
    private var customToolPalette: some View {
        VStack(spacing: 16) {
            // Tool selection
            HStack(spacing: 20) {
                ForEach(DrawingTool.allCases, id: \.self) { tool in
                    ToolButton(
                        tool: tool,
                        isSelected: selectedTool == tool,
                        action: { selectedTool = tool }
                    )
                }
            }
            
            Divider()
            
            // Color selection
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(academicColors, id: \.self) { color in
                        ColorButton(
                            color: color,
                            isSelected: selectedColor == color,
                            action: { selectedColor = color }
                        )
                    }
                    
                    // Custom color picker
                    Button {
                        showingColorPicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "plus")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Line width slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stroke Width")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(lineWidth))pt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $lineWidth, in: 1...20, step: 1)
                    .tint(selectedColor)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(radius: 10)
        )
        .padding()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                if isDrawingModified {
                    // Show confirmation
                } else {
                    dismiss()
                }
            }
        }
        
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Button {
                    showingBackgroundOptions = true
                } label: {
                    Label("Background", systemImage: "square.grid.3x3")
                }
                
                Button {
                    toggleToolPicker()
                } label: {
                    Label(
                        isToolPickerActive ? "Custom Tools" : "System Tools",
                        systemImage: isToolPickerActive ? "paintpalette" : "pencil.tip"
                    )
                }
                
                Divider()
                
                Button {
                    exportDrawing()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            
            Button("Save") {
                saveDrawing()
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Methods
    
    private func setupCanvas() {
        if let drawingCanvas = drawingCanvas {
           let drawingData = drawingCanvas.canvasData
            do {
                canvasView.drawing = try PKDrawing(data: drawingData)
            } catch {
                print("Failed to load drawing: \(error)")
            }
        }
        
        // Configure canvas
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        
        // Set initial tool
        updateCanvasTool()
    }
    
    private func updateCanvasTool() {
        let inkType: PKInk.InkType
        switch selectedTool {
        case .pen:
            inkType = .pen
        case .pencil:
            inkType = .pencil
        case .marker:
            inkType = .marker
        case .highlighter:
            inkType = .marker
        case .eraser:
            canvasView.tool = PKEraserTool(.vector)
            return
        case .line, .rectangle, .circle, .arrow, .text:
            inkType = .pen
        }
        
        canvasView.tool = PKInkingTool(inkType, color: UIColor(selectedColor), width: lineWidth)
    }
    
    private func toggleToolPicker() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isToolPickerActive.toggle()
        }
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        isDrawingModified = true
    }
    
    private func saveDrawing() {
        let drawing = canvasView.drawing
        
        if let drawingCanvas = drawingCanvas {
            // Update existing
            drawingCanvas.canvasData = drawing.dataRepresentation()
            drawingCanvas.lastModified = Date()
        } else if let lesson = lesson {
            // Create new
            let newCanvas = DrawingCanvas(title: "Drawing \(Date())")
            newCanvas.canvasData = drawing.dataRepresentation()
            
            // TODO: Implement proper storage for drawings
            // For now, just print that we would save the drawing
            print("Would save drawing to lesson: \(lesson.title)")
        }
        
        onSave?(drawing)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save drawing: \(error)")
        }
    }
    
    private func exportDrawing() {
        let drawing = canvasView.drawing
        let bounds = drawing.bounds
        
        // Generate image
        let scale = UIScreen.main.scale
        
        let image = drawing.image(from: bounds, scale: scale)
        
        // Share image
        let activityController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - Supporting Types

// Note: DrawingTool enum is defined in DrawingCanvas.swift

enum BackgroundType: String, CaseIterable {
    case blank = "Blank"
    case grid = "Grid"
    case ruled = "Ruled"
    case dotted = "Dotted"
}

// MARK: - Supporting Views

struct ToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: tool.iconName)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
        }
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                        .padding(2)
                )
        }
    }
}

// MARK: - PencilKit Canvas Wrapper

struct PencilKitCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isToolPickerActive: Bool
    let selectedTool: DrawingTool
    let selectedColor: Color
    let lineWidth: CGFloat
    let onDrawingChanged: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        // Setup tool picker if active
        if isToolPickerActive {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if !isToolPickerActive {
            // Update tool based on selection
            updateTool(for: uiView)
        }
    }
    
    private func updateTool(for canvasView: PKCanvasView) {
        if selectedTool == .eraser {
            canvasView.tool = PKEraserTool(.vector)
        } else {
            let inkType: PKInk.InkType = {
                switch selectedTool {
                case .pen: return .pen
                case .pencil: return .pencil
                case .marker: return .marker
                case .eraser: return .pen // Won't reach here
                case .highlighter: return .marker
                case .line: return .pen
                case .rectangle: return .pen
                case .circle: return .pen
                case .arrow: return .pen
                case .text: return .pen
                }
            }()
            
            canvasView.tool = PKInkingTool(
                inkType,
                color: UIColor(selectedColor),
                width: lineWidth
            )
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: () -> Void
        
        init(onDrawingChanged: @escaping () -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged()
        }
    }
}

// MARK: - Background Views

struct GridBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 20
                let columns = Int(geometry.size.width / gridSize)
                let rows = Int(geometry.size.height / gridSize)
                
                // Vertical lines
                for column in 0...columns {
                    let x = CGFloat(column) * gridSize
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
                
                // Horizontal lines
                for row in 0...rows {
                    let y = CGFloat(row) * gridSize
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        }
        .ignoresSafeArea()
    }
}

struct RuledBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let lineSpacing: CGFloat = 30
                let rows = Int(geometry.size.height / lineSpacing)
                
                for row in 0...rows {
                    let y = CGFloat(row) * lineSpacing + 20
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        }
        .ignoresSafeArea()
    }
}

struct DottedBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let dotSpacing: CGFloat = 20
                let columns = Int(geometry.size.width / dotSpacing)
                let rows = Int(geometry.size.height / dotSpacing)
                
                for column in 0...columns {
                    for row in 0...rows {
                        let x = CGFloat(column) * dotSpacing
                        let y = CGFloat(row) * dotSpacing
                        path.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                    }
                }
            }
            .fill(Color.secondary.opacity(0.3))
        }
        .ignoresSafeArea()
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ColorPicker("Choose Color", selection: $selectedColor)
                .padding()
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Background Options View

struct BackgroundOptionsView: View {
    @Binding var selectedBackground: BackgroundType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(BackgroundType.allCases, id: \.self) { background in
                    HStack {
                        Text(background.rawValue)
                        
                        Spacer()
                        
                        if selectedBackground == background {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBackground = background
                        dismiss()
                    }
                }
            }
            .navigationTitle("Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DrawingCanvasView(lesson: nil, drawingCanvas: nil, onSave: nil)
} 