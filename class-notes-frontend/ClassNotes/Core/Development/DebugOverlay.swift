//
//  DebugOverlay.swift
//  class-notes-frontend
//
//  Visual debugging overlay for development
//

#if DEBUG
import SwiftUI
import UIKit

// MARK: - Debug Overlay View Modifier
struct DebugOverlay: ViewModifier {
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("debug_show_overlay") private var showDebugOverlay = false
    
    // Performance monitoring
    @State private var memoryUsage: String = "Calculating..."
    @State private var cpuUsage: String = "0%"
    @State private var frameRate: String = "60 FPS"
    
    let updateTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if showDebugOverlay {
                    debugInfoView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .onReceive(updateTimer) { _ in
                updatePerformanceMetrics()
            }
    }
    
    private var debugInfoView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Device Info Section
            VStack(alignment: .trailing, spacing: 4) {
                Label("Device", systemImage: "ipad")
                    .font(.caption2.bold())
                
                Text("\(UIDevice.current.name)")
                    .font(.caption2)
                
                Text("iOS \(UIDevice.current.systemVersion)")
                    .font(.caption2)
                
                HStack(spacing: 4) {
                    Text("Size:")
                    Text("\(hSizeClass == .compact ? "Compact" : "Regular") × \(vSizeClass == .compact ? "Compact" : "Regular")")
                }
                .font(.caption2)
                
                Text("\(colorScheme == .light ? "Light" : "Dark") Mode")
                    .font(.caption2)
            }
            
            Divider()
                .frame(width: 150)
            
            // Performance Section
            VStack(alignment: .trailing, spacing: 4) {
                Label("Performance", systemImage: "speedometer")
                    .font(.caption2.bold())
                
                HStack {
                    Text("Memory:")
                    Text(memoryUsage)
                        .monospacedDigit()
                }
                .font(.caption2)
                
                HStack {
                    Text("CPU:")
                    Text(cpuUsage)
                        .monospacedDigit()
                }
                .font(.caption2)
                
                HStack {
                    Text("Frame Rate:")
                    Text(frameRate)
                        .monospacedDigit()
                }
                .font(.caption2)
            }
            
            Divider()
                .frame(width: 150)
            
            // App Info Section
            VStack(alignment: .trailing, spacing: 4) {
                Label("App Info", systemImage: "info.circle")
                    .font(.caption2.bold())
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version: \(version)")
                        .font(.caption2)
                }
                
                if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Build: \(build)")
                        .font(.caption2)
                }
                
                Text("Environment: DEBUG")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            // Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDebugOverlay.toggle()
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }
    
    private func updatePerformanceMetrics() {
        // Memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0
            memoryUsage = String(format: "%.1f MB", usedMemory)
        }
        
        // CPU usage (simplified)
        let cpuInfo = ProcessInfo.processInfo
        let processorCount = cpuInfo.processorCount
        cpuUsage = "\(processorCount) cores"
        
        // Frame rate (placeholder - would need CADisplayLink for accurate measurement)
        frameRate = "60 FPS"
    }
}

// MARK: - Grid Overlay
struct GridOverlay: ViewModifier {
    @AppStorage("debug_show_grid") private var showGrid = false
    let spacing: CGFloat
    
    init(spacing: CGFloat = 20) {
        self.spacing = spacing
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if showGrid {
                    GeometryReader { geometry in
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            
                            // Vertical lines
                            for x in stride(from: 0, through: width, by: spacing) {
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: height))
                            }
                            
                            // Horizontal lines
                            for y in stride(from: 0, through: height, by: spacing) {
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: width, y: y))
                            }
                        }
                        .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                    }
                }
            }
    }
}

// MARK: - Touch Indicator
struct TouchIndicator: ViewModifier {
    @AppStorage("debug_show_touches") private var showTouches = false
    @GestureState private var touchLocation: CGPoint?
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if showTouches, let location = touchLocation {
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 50, height: 50)
                        .position(location)
                        .allowsHitTesting(false)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($touchLocation) { value, state, _ in
                        if showTouches {
                            state = value.location
                        }
                    }
            )
    }
}

// MARK: - View Extensions
extension View {
    /// Adds debug overlay showing device and performance information
    func debugOverlay() -> some View {
        modifier(DebugOverlay())
    }
    
    /// Adds grid overlay for alignment debugging
    func debugGrid(spacing: CGFloat = 20) -> some View {
        modifier(GridOverlay(spacing: spacing))
    }
    
    /// Shows touch indicators for debugging interactions
    func debugTouches() -> some View {
        modifier(TouchIndicator())
    }
    
    /// Adds all debug overlays
    func debugMode() -> some View {
        self
            .debugOverlay()
            .debugGrid()
            .debugTouches()
    }
}

// MARK: - Debug Toggle View
struct DebugToggleView: View {
    @AppStorage("debug_show_overlay") private var showOverlay = false
    @AppStorage("debug_show_grid") private var showGrid = false
    @AppStorage("debug_show_touches") private var showTouches = false
    
    var body: some View {
        Menu {
            Toggle("Show Debug Overlay", isOn: $showOverlay)
            Toggle("Show Grid", isOn: $showGrid)
            Toggle("Show Touch Indicators", isOn: $showTouches)
        } label: {
            Image(systemName: "hammer.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
        }
    }
}
#endif 