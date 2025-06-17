import SwiftUI

#if os(iOS)
    import PencilKit

    /// Demo view to test PencilKit integration
    struct PencilKitDemoView: View {
        @State private var canvasView = PKCanvasView()
        @State private var isToolPickerActive = true

        var body: some View {
            NavigationStack {
                VStack {
                    Text("Draw something to test PencilKit!")
                        .font(.headline)
                        .padding()

                    PencilKitDrawingView(
                        canvasView: $canvasView,
                        isToolPickerActive: $isToolPickerActive,
                        isReadOnly: false
                    )
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding()

                    HStack(spacing: 20) {
                        Button("Clear") {
                            canvasView.drawing = PKDrawing()
                        }
                        .buttonStyle(.bordered)

                        Button("Toggle Tools") {
                            isToolPickerActive.toggle()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                .navigationTitle("PencilKit Demo")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

    #Preview {
        PencilKitDemoView()
    }
#else
    struct PencilKitDemoView: View {
        var body: some View {
            Text("PencilKit demo is only available on iOS/iPadOS")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
    }
#endif
