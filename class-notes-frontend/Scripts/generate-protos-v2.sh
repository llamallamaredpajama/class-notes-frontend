#!/bin/bash

# generate-protos-v2.sh
# Script to generate Swift code from proto files for grpc-swift-2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting proto generation for grpc-swift-2...${NC}"

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
FRONTEND_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BACKEND_PROTO_DIR="$PROJECT_ROOT/Backend/proto"
LOCAL_PROTO_DIR="$FRONTEND_ROOT/ClassNotes/Core/Networking/gRPC/Protos"
OUTPUT_DIR="$FRONTEND_ROOT/ClassNotes/Core/Networking/gRPC/Generated"

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

# Check if grpc-swift-protobuf plugin is installed
if ! command -v protoc-gen-grpc-swift &> /dev/null; then
    echo -e "${YELLOW}protoc-gen-grpc-swift is not installed. Installing it now...${NC}"
    # Build the plugin from the grpc-swift-protobuf package
    cd "$FRONTEND_ROOT"
    swift build --package-path . --product protoc-gen-grpc-swift
    PLUGIN_PATH="$FRONTEND_ROOT/.build/debug/protoc-gen-grpc-swift"
else
    PLUGIN_PATH="protoc-gen-grpc-swift"
fi

echo -e "${GREEN}Cleaning old generated files...${NC}"
rm -f "$OUTPUT_DIR"/*.swift

# Generate from local proto files first (subscription.proto)
if [ -d "$LOCAL_PROTO_DIR" ]; then
    echo -e "${GREEN}Generating from local proto files...${NC}"
    PROTO_FILES=$(find "$LOCAL_PROTO_DIR" -name "*.proto")
    
    for proto_file in $PROTO_FILES; do
        echo -e "Processing: $proto_file"
        
        protoc \
            --proto_path="$LOCAL_PROTO_DIR" \
            --proto_path="$BACKEND_PROTO_DIR" \
            --proto_path="$PROJECT_ROOT/Backend/include" \
            --swift_out="$OUTPUT_DIR" \
            --swift_opt=Visibility=Public \
            --plugin="$PLUGIN_PATH" \
            --grpc-swift_out="$OUTPUT_DIR" \
            --grpc-swift_opt=Visibility=Public \
            --grpc-swift_opt=Client=true \
            --grpc-swift_opt=Server=false \
            "$proto_file"
    done
fi

# Generate from backend proto files
if [ -d "$BACKEND_PROTO_DIR" ]; then
    echo -e "${GREEN}Generating from backend proto files...${NC}"
    PROTO_FILES=$(find "$BACKEND_PROTO_DIR/classnotes" -name "*.proto" -not -path "*/google/*" 2>/dev/null || true)
    
    for proto_file in $PROTO_FILES; do
        echo -e "Processing: $proto_file"
        
        protoc \
            --proto_path="$BACKEND_PROTO_DIR" \
            --proto_path="$PROJECT_ROOT/Backend/include" \
            --swift_out="$OUTPUT_DIR" \
            --swift_opt=Visibility=Public \
            --plugin="$PLUGIN_PATH" \
            --grpc-swift_out="$OUTPUT_DIR" \
            --grpc-swift_opt=Visibility=Public \
            --grpc-swift_opt=Client=true \
            --grpc-swift_opt=Server=false \
            "$proto_file" || echo -e "${YELLOW}Warning: Failed to process $proto_file${NC}"
    done
fi

echo -e "${GREEN}Proto generation complete!${NC}"
echo -e "${GREEN}Generated files are in: $OUTPUT_DIR${NC}"

# Make the script executable
chmod +x "$0" 