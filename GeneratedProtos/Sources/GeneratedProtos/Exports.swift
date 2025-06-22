// Exports.swift
// Re-export all gRPC types so the main app only needs to import GeneratedProtos

@_exported import GRPCCore
@_exported import GRPCNIOTransportHTTP2
@_exported import GRPCProtobuf
@_exported import SwiftProtobuf

// Note: GRPCNIOTransportHTTP2 needs to be added to Package.swift dependencies first
