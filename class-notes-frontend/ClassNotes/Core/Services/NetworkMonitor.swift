// 1. Standard library
import Foundation

// 2. Apple frameworks
import Network
import Combine
import OSLog

/// Monitors network connectivity status
@MainActor
class NetworkMonitor: ObservableObject {
    // MARK: - Properties
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Connection Types
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    // MARK: - Singleton
    
    static let shared = NetworkMonitor()
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    // MARK: - Methods
    
    /// Start monitoring network status
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
                
                // Log network status changes
                OSLog.networking.info("Network status changed: \(path.status == .satisfied ? "Connected" : "Disconnected")")
                
                // Post notification for other components
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: ["isConnected": path.status == .satisfied]
                )
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// Update the connection type based on the network path
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    /// Stop monitoring network status
    func stopMonitoring() {
        monitor.cancel()
    }
    
    /// Check if we should sync data (WiFi or Ethernet only for large uploads)
    func shouldSyncLargeData() -> Bool {
        return isConnected && (connectionType == .wifi || connectionType == .ethernet)
    }
    
    /// Wait for network connection
    func waitForConnection() async {
        if isConnected { return }
        
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = $isConnected
                .dropFirst()
                .filter { $0 }
                .first()
                .sink { _ in
                    continuation.resume()
                    cancellable?.cancel()
                }
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
} 