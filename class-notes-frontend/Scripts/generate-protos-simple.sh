#!/bin/bash

# generate-protos-simple.sh
# Simple script to generate Swift code from proto files for grpc-swift-2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting proto generation for grpc-swift-2...${NC}"

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRONTEND_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
OUTPUT_DIR="$FRONTEND_ROOT/ClassNotes/Core/Networking/gRPC/Generated"
PROTO_DIR="$FRONTEND_ROOT/ClassNotes/Core/Networking/gRPC/Protos"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo -e "${RED}protoc is not installed. Please run: brew install protobuf${NC}"
    exit 1
fi

# Check if swift-protobuf plugin is installed
if ! command -v protoc-gen-swift &> /dev/null; then
    echo -e "${RED}protoc-gen-swift is not installed. Please run: brew install swift-protobuf${NC}"
    exit 1
fi

# Check if grpc-swift plugin is installed
if ! command -v protoc-gen-grpc-swift &> /dev/null; then
    echo -e "${RED}protoc-gen-grpc-swift is not installed.${NC}"
    echo -e "${YELLOW}Please run: ./install-grpc-tools.sh${NC}"
    exit 1
fi

echo -e "${GREEN}Cleaning old generated files...${NC}"
rm -f "$OUTPUT_DIR"/*.swift

# Generate from local proto files
echo -e "${GREEN}Generating Swift files from proto...${NC}"

# Generate subscription.proto
if [ -f "$PROTO_DIR/subscription.proto" ]; then
    echo -e "${GREEN}Processing subscription.proto...${NC}"
    
    protoc \
        --proto_path="$PROTO_DIR" \
        --swift_out="$OUTPUT_DIR" \
        --swift_opt=Visibility=Public \
        --grpc-swift_out="$OUTPUT_DIR" \
        --grpc-swift_opt=Visibility=Public \
        --grpc-swift_opt=Client=true \
        --grpc-swift_opt=Server=false \
        "$PROTO_DIR/subscription.proto"
fi

# Check if we have the classnotes service proto locally or need to get it
CLASSNOTES_PROTO="/Users/jeremy/Code/class-notes-project/classnotes-devops/proto-management/proto/classnotes/v1/classnotes_service.proto"
if [ -f "$CLASSNOTES_PROTO" ]; then
    echo -e "${GREEN}Processing classnotes_service.proto...${NC}"
    
    # Copy it locally first
    cp "$CLASSNOTES_PROTO" "$PROTO_DIR/classnotes_service.proto"
    
    protoc \
        --proto_path="$PROTO_DIR" \
        --swift_out="$OUTPUT_DIR" \
        --swift_opt=Visibility=Public \
        --grpc-swift_out="$OUTPUT_DIR" \
        --grpc-swift_opt=Visibility=Public \
        --grpc-swift_opt=Client=true \
        --grpc-swift_opt=Server=false \
        "$PROTO_DIR/classnotes_service.proto"
fi

echo -e "${GREEN}Proto generation complete!${NC}"
echo -e "${GREEN}Generated files are in: $OUTPUT_DIR${NC}"

# List generated files
echo -e "${YELLOW}Generated files:${NC}"
ls -la "$OUTPUT_DIR"/*.swift 2>/dev/null || echo "No files generated"

# Make the script executable
chmod +x "$0" 