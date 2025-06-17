#!/bin/bash

# Script to generate Swift code from proto files using grpc-swift-2
# This regenerates all gRPC client code for the ClassNotes project

set -e

echo "Generating Swift code from proto files for grpc-swift-2..."

# Define paths
FRONTEND_DIR="/Users/jeremy/Code/class-notes-project/class-notes-frontend"
BACKEND_DIR="/Users/jeremy/Code/class-notes-project/classnotes-devops"
PROTO_OUTPUT_DIR="$FRONTEND_DIR/ClassNotes/Core/Networking/gRPC/Generated"

# Clean the output directory to remove stale files before generation
echo "Cleaning output directory: $PROTO_OUTPUT_DIR"
rm -rf "$PROTO_OUTPUT_DIR"
mkdir -p "$PROTO_OUTPUT_DIR"

echo "Output directory: $PROTO_OUTPUT_DIR"

# Find all proto files
PROTO_FILES=()

# Local proto files (found in class-notes-frontend subdirectory)
LOCAL_PROTO="$FRONTEND_DIR/class-notes-frontend/ClassNotes/Core/Networking/gRPC/Protos/subscription.proto"
if [ -f "$LOCAL_PROTO" ]; then
    PROTO_FILES+=("$LOCAL_PROTO")
    echo "Found local proto: subscription.proto"
fi

# Backend proto files (found in proto-management)
BACKEND_PROTO="$BACKEND_DIR/proto-management/proto/classnotes/v1/classnotes_service.proto"
if [ -f "$BACKEND_PROTO" ]; then
    PROTO_FILES+=("$BACKEND_PROTO")
    echo "Found backend proto: classnotes_service.proto"
fi

# Check if we found any proto files
if [ ${#PROTO_FILES[@]} -eq 0 ]; then
    echo "Warning: No proto files found!"
    echo "Checked locations:"
    echo "  - $LOCAL_PROTO"
    echo "  - $BACKEND_PROTO"
    echo ""
    echo "Searching for .proto files recursively..."
    find "$FRONTEND_DIR" -name "*.proto" 2>/dev/null || true
    find "$BACKEND_DIR" -name "*.proto" 2>/dev/null | grep -E "(classnotes|subscription)" | head -5 || true
    
    exit 1
fi

echo "Found ${#PROTO_FILES[@]} proto file(s)"

# Generate Swift code for each proto file
for proto_file in "${PROTO_FILES[@]}"; do
    echo ""
    echo "Processing: $(basename $proto_file)"
    
    # Get the directory containing the proto file for import resolution
    proto_dir=$(dirname "$proto_file")
    
    # For the backend proto, we need to add the proto-management directory to the path
    if [[ "$proto_file" == *"proto-management"* ]]; then
        proto_base_dir="$BACKEND_DIR/proto-management"
        
        echo "Generating from backend proto with base path: $proto_base_dir"
        protoc \
            --proto_path="$proto_base_dir" \
            --swift_out="$PROTO_OUTPUT_DIR" \
            --grpc-swift_out="$PROTO_OUTPUT_DIR" \
            "proto/classnotes/v1/classnotes_service.proto"
    else
        # For local protos, use the standard approach
        echo "Generating from local proto"
        protoc \
            --proto_path="$proto_dir" \
            --swift_out="$PROTO_OUTPUT_DIR" \
            --grpc-swift_out="$PROTO_OUTPUT_DIR" \
            "$proto_file"
    fi
    
    echo "✓ Generated Swift code for $(basename $proto_file)"
done

echo ""
echo "Code generation complete!"
echo ""
echo "Generated files in: $PROTO_OUTPUT_DIR"
ls -la "$PROTO_OUTPUT_DIR" 2>/dev/null || echo "Directory is empty or doesn't exist"

echo ""
echo "Next steps:"
echo "1. Add generated files to your Xcode project"
echo "2. Update import statements in your code to use GRPCCore"
echo "3. Build the project to verify everything works"
echo ""
echo "If you see compilation errors:"
echo "- Make sure all generated files are added to the Xcode project"
echo "- Verify that grpc-swift-2 packages are properly configured"
echo "- Check that import statements match the new API" 