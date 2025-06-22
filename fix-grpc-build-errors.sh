#!/bin/bash

echo "🔧 Fixing gRPC-Swift v2 Build Errors"
echo "===================================="

# 1. Ensure generated files are in the project
echo "Step 1: Checking generated proto files..."
if [ -f "ClassNotes/Core/Networking/gRPC/Generated/classnotes_service.pb.swift" ]; then
    echo "✅ Proto files exist"
else
    echo "❌ Proto files missing - regenerating..."
    cd ../classnotes-devops/proto-management
    buf generate proto --template /Users/jeremy/Code/class-notes-project/class-notes-frontend/buf.gen.yaml
    cd -
fi

# 2. Create a bridging header if needed
echo -e "\nStep 2: Important steps to complete in Xcode:"
echo "1. Add Generated Files to Target:"
echo "   - In Xcode, right-click on the Generated folder"
echo "   - Choose 'Add Files to \"class-notes-frontend\"'"
echo "   - Select both .pb.swift and .grpc.swift files"
echo "   - Make sure 'Copy items if needed' is UNCHECKED"
echo "   - Make sure your app target is CHECKED"
echo ""
echo "2. Check iOS Deployment Target:"
echo "   - Select project → Target → General"
echo "   - Ensure 'Minimum Deployments' is set to iOS 18.0 or later"
echo ""
echo "3. Clean and Rebuild:"
echo "   - Product → Clean Build Folder (⇧⌘K)"
echo "   - Product → Build (⌘B)"

# 3. Create fixed interceptor imports
echo -e "\nStep 3: Fixing import issues..."
cat > ClassNotes/Core/Networking/gRPC/Shared/GRPCImports.swift << 'IMPORTS'
// Shared imports for gRPC-Swift v2
import Foundation
import GRPCCore
import GRPCProtobuf
import GRPCNIOTransportHTTP2
import NIOCore
import NIOPosix
import SwiftProtobuf

// Re-export commonly used types
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
IMPORTS

echo "✅ Created GRPCImports.swift"

echo -e "\n✅ Script complete! Follow the Xcode steps above to finish fixing the errors."
