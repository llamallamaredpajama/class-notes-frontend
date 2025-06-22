import Foundation

/// Global actor for synchronizing access to gRPC client operations
@globalActor
actor GRPCClientActor {
    static let shared = GRPCClientActor()

    private init() {}
}
