import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif
#if canImport(PencilKit)
    import PencilKit
#endif

/// A SwiftUI wrapper for PKCanvasView to enable drawing with PencilKit
struct PencilKitDrawingView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isToolPickerActive: Bool
    let isReadOnly: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .systemBackground
        canvasView.isOpaque = false
        canvasView.alwaysBounceVertical = true
        canvasView.isScrollEnabled = true

        // Set up the tool picker
        if !isReadOnly {
            context.coordinator.toolPicker = PKToolPicker()
            context.coordinator.toolPicker?.setVisible(
                isToolPickerActive, forFirstResponder: canvasView)
            context.coordinator.toolPicker?.addObserver(canvasView)

            // Update binding when tool picker visibility changes
            context.coordinator.toolPicker?.addObserver(context.coordinator)

            if isToolPickerActive {
                canvasView.becomeFirstResponder()
            }
        }

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = !isReadOnly

        if !isReadOnly {
            context.coordinator.toolPicker?.setVisible(
                isToolPickerActive, forFirstResponder: uiView)

            if isToolPickerActive {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        var parent: PencilKitDrawingView
        var toolPicker: PKToolPicker?

        init(_ parent: PencilKitDrawingView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Handle drawing changes if needed
        }

        func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
            parent.isToolPickerActive = toolPicker.isVisible
        }
    }
}

/// Preview wrapper for PencilKitDrawingView
struct DrawingViewWrapper: View {
    @State private var canvasView = PKCanvasView()
    @State private var isToolPickerActive = false

    var body: some View {
        PencilKitDrawingView(
            canvasView: $canvasView,
            isToolPickerActive: $isToolPickerActive,
            isReadOnly: false
        )
    }
}

#Preview {
    DrawingViewWrapper()
}
