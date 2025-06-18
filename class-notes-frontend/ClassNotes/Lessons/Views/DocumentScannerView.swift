import SwiftUI
import VisionKit
import PDFKit

/// View for scanning documents using VisionKit
struct DocumentScannerView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var showingEditView = false
    @State private var selectedImageIndex = 0
    @State private var scanQuality: ScanQuality = .high
    
    let lesson: Lesson?
    let onCompletion: (([UIImage]) -> Void)?
    
    // MARK: - Initialization
    
    init(lesson: Lesson? = nil, onCompletion: (([UIImage]) -> Void)? = nil) {
        self.lesson = lesson
        self.onCompletion = onCompletion
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if scannedImages.isEmpty {
                    emptyScanView
                } else {
                    scannedDocumentsView
                }
                
                if isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle("Document Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showingScanner) {
                DocumentScanner(scannedImages: $scannedImages, quality: scanQuality)
            }
            .sheet(isPresented: $showingEditView) {
                DocumentEditView(
                    images: $scannedImages,
                    selectedIndex: selectedImageIndex
                )
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyScanView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 200, height: 250)
                
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Image(systemName: "arrow.down")
                        .font(.title)
                        .foregroundColor(.accentColor.opacity(0.5))
                }
            }
            
            VStack(spacing: 12) {
                Text("Scan Your Documents")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Turn physical notes and handouts\ninto digital documents")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Quality selector
            qualitySelector
                .padding(.horizontal, 40)
            
            Button {
                showingScanner = true
            } label: {
                Label("Start Scanning", systemImage: "camera.viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
    
    private var scannedDocumentsView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(Array(scannedImages.enumerated()), id: \.offset) { index, image in
                    ScannedPageView(
                        image: image,
                        index: index,
                        onTap: {
                            selectedImageIndex = index
                            showingEditView = true
                        },
                        onDelete: {
                            deleteImage(at: index)
                        }
                    )
                }
                
                // Add more pages button
                Button {
                    showingScanner = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        
                        Text("Add Page")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(0.77, contentMode: .fit)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.secondary.opacity(0.3))
                            )
                    )
                }
            }
            .padding()
        }
    }
    
    private var qualitySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scan Quality")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("Scan Quality", selection: $scanQuality) {
                ForEach(ScanQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Processing Documents...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
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
            if !scannedImages.isEmpty {
                Button("Done") {
                    saveDocuments()
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - Methods
    
    private func deleteImage(at index: Int) {
        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            scannedImages.remove(at: index)
        }
    }
    
    private func saveDocuments() {
        isProcessing = true
        
        Task {
            // Create PDF from images
            let pdfDocument = PDFDocument()
            
            for (index, image) in scannedImages.enumerated() {
                if let pdfPage = PDFPage(image: image) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            // Save to lesson or return via completion
            if let lesson = lesson {
                // Create ScannedDocument objects from images
                let newDocuments = scannedImages.enumerated().map { index, imageData in
                    return ScannedDocument(
                        title: "Scanned Page \(index + 1)",
                        pageCount: 1
                    )
                }
                
                if lesson.scannedDocuments == nil {
                    lesson.scannedDocuments = []
                }
                lesson.scannedDocuments?.append(contentsOf: newDocuments)
                
                try? modelContext.save()
            }
            
            onCompletion?(scannedImages)
            
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Types

enum ScanQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var displayName: String { rawValue }
    
    var compressionQuality: Double {
        switch self {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }
}

// MARK: - Document Scanner Wrapper

struct DocumentScanner: UIViewControllerRepresentable {
    @Binding var scannedImages: [UIImage]
    let quality: ScanQuality
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        
        init(_ parent: DocumentScanner) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var newImages: [UIImage] = []
            
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                
                // Apply quality compression
                if let compressedData = image.jpegData(compressionQuality: parent.quality.compressionQuality),
                   let compressedImage = UIImage(data: compressedData) {
                    newImages.append(compressedImage)
                } else {
                    newImages.append(image)
                }
            }
            
            parent.scannedImages.append(contentsOf: newImages)
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Scanned Page View

struct ScannedPageView: View {
    let image: UIImage
    let index: Int
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onTapGesture {
                    onTap()
                }
            
            HStack {
                Text("Page \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 4)
        }
        .confirmationDialog("Delete Page?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This page will be removed from the scan.")
        }
    }
}

// MARK: - Document Edit View

struct DocumentEditView: View {
    @Binding var images: [UIImage]
    let selectedIndex: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1
    @State private var rotation: Angle = .zero
    
    init(images: Binding<[UIImage]>, selectedIndex: Int) {
        self._images = images
        self.selectedIndex = selectedIndex
        self._currentIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image preview
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .brightness(brightness)
                            .contrast(contrast)
                            .rotationEffect(rotation)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Editing controls
                VStack(spacing: 20) {
                    // Brightness
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Brightness", systemImage: "sun.max")
                            .font(.subheadline)
                        Slider(value: $brightness, in: -0.5...0.5)
                    }
                    
                    // Contrast
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Contrast", systemImage: "circle.lefthalf.filled")
                            .font(.subheadline)
                        Slider(value: $contrast, in: 0.5...1.5)
                    }
                    
                    // Rotation buttons
                    HStack(spacing: 20) {
                        Button {
                            withAnimation {
                                rotation -= .degrees(90)
                            }
                        } label: {
                            Label("Rotate Left", systemImage: "rotate.left")
                        }
                        
                        Button {
                            withAnimation {
                                rotation += .degrees(90)
                            }
                        } label: {
                            Label("Rotate Right", systemImage: "rotate.right")
                        }
                        
                        Spacer()
                        
                        Button {
                            resetEdits()
                        } label: {
                            Text("Reset")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Edit Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyEdits()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func resetEdits() {
        withAnimation {
            brightness = 0
            contrast = 1
            rotation = .zero
        }
    }
    
    private func applyEdits() {
        // TODO: Apply image filters and rotation
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    DocumentScannerView()
} 