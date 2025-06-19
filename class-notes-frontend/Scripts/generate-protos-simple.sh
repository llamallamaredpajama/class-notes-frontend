#!/bin/bash

# Simple gRPC-Swift v2 Proto Generation Script
# This script generates Swift protobuf and gRPC client code from proto files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRONTEND_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
PROJECT_ROOT="/Users/jeremy/Code/class-notes-project"
DEVOPS_DIR="$PROJECT_ROOT/classnotes-devops"

echo -e "${GREEN}Simple gRPC-Swift v2 Proto Generation${NC}"
echo "Frontend directory: $FRONTEND_DIR"
echo "DevOps directory: $DEVOPS_DIR"

# Check if buf is installed
if ! command -v buf &> /dev/null; then
    echo -e "${RED}Error: buf is not installed${NC}"
    echo "Install buf from: https://docs.buf.build/installation"
    exit 1
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="$FRONTEND_DIR/ClassNotes/Core/Networking/gRPC/Generated"
mkdir -p "$OUTPUT_DIR"

# Clean existing generated files
echo -e "${YELLOW}Cleaning existing generated files...${NC}"
rm -rf "$OUTPUT_DIR"/*.swift

# Change to DevOps directory where proto files are located
cd "$DEVOPS_DIR"

# Generate proto files using the DevOps proto directory
echo -e "${GREEN}Generating Swift protobuf and gRPC code from DevOps protos...${NC}"

# Use buf to generate with the frontend's buf.gen.yaml
if [ -f "proto-management/proto" ]; then
    cd proto-management
fi

buf generate proto --template "$FRONTEND_DIR/buf.gen.yaml"

# Count generated files
GENERATED_COUNT=$(find "$OUTPUT_DIR" -name "*.swift" | wc -l | tr -d ' ')

if [ "$GENERATED_COUNT" -eq "0" ]; then
    echo -e "${RED}Error: No files were generated${NC}"
    echo "Trying direct protoc generation as fallback..."
    
    # Fallback to direct protoc generation
    cd "$DEVOPS_DIR/proto-management"
    
    # Generate protobuf files
    protoc --swift_out="$OUTPUT_DIR" \
           --swift_opt=Visibility=Public \
           --swift_opt=FileNaming=DropPath \
           proto/classnotes/v1/classnotes_service.proto
    
    # Generate gRPC files
    protoc --grpc-swift_out="$OUTPUT_DIR" \
           --grpc-swift_opt=Visibility=Public \
           --grpc-swift_opt=Client=true \
           --grpc-swift_opt=Server=false \
           proto/classnotes/v1/classnotes_service.proto
    
    GENERATED_COUNT=$(find "$OUTPUT_DIR" -name "*.swift" | wc -l | tr -d ' ')
fi

echo -e "${GREEN}Successfully generated $GENERATED_COUNT Swift files${NC}"

# Fix imports in generated files to ensure gRPC Swift v2 compatibility
echo -e "${YELLOW}Fixing imports for gRPC Swift v2...${NC}"
for file in "$OUTPUT_DIR"/*.swift; do
    if [ -f "$file" ]; then
        # The import GRPCProtobuf is actually correct for v2, so we don't need to change it
        # Just ensure we're not using old v1 imports
        sed -i '' 's/import GRPC$/import GRPCCore/g' "$file" 2>/dev/null || true
        sed -i '' 's/import NIO$/import NIOCore/g' "$file" 2>/dev/null || true
    fi
done

echo -e "${GREEN}Proto generation complete!${NC}"
echo ""
echo "Generated files are in: $OUTPUT_DIR"
echo ""
echo -e "${YELLOW}Note: The 'import GRPCProtobuf' in generated files is correct for gRPC Swift v2${NC}"
echo "GRPCProtobuf is the v2 module for protobuf serialization/deserialization." 