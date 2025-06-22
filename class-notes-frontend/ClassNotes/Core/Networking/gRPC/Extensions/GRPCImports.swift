// GRPCImports.swift
// Shared imports and type aliases for gRPC-Swift v2
// This file ensures consistent type usage across all gRPC code

import Foundation
import GeneratedProtos
import NIOCore
import NIOPosix

// Re-export commonly used types for convenience
public typealias GRPCClient = GRPCCore.GRPCClient
public typealias ClientInterceptor = GRPCCore.ClientInterceptor
public typealias ClientRequest = GRPCCore.ClientRequest
public typealias ClientResponse = GRPCCore.ClientResponse
public typealias Metadata = GRPCCore.Metadata
public typealias RPCError = GRPCCore.RPCError
public typealias CallOptions = GRPCCore.CallOptions

// Serialization helpers
public typealias ProtobufSerializer<T: Message> = GRPCProtobuf.ProtobufSerializer<T>
public typealias ProtobufDeserializer<T: Message> = GRPCProtobuf.ProtobufDeserializer<T>

// Type aliases to simplify usage
public typealias GRPCTransport = HTTP2ClientTransport.Posix
public typealias GRPCClientType = GRPCClient<GRPCTransport>

// Re-export common types
public typealias StreamingClientRequest = GRPCCore.StreamingClientRequest
public typealias StreamingClientResponse = GRPCCore.StreamingClientResponse
public typealias ClientContext = GRPCCore.ClientContext
