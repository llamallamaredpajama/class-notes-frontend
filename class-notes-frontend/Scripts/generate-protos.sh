#!/bin/bash

# generate-protos.sh
# Script to generate Swift code from proto files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting proto generation for iOS...${NC}"

# Paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../../.." && pwd )"
BACKEND_PROTO_DIR="$PROJECT_ROOT/Backend/proto"
OUTPUT_DIR="$SCRIPT_DIR/../ClassNotes/Core/Networking/gRPC/Generated"

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
    echo -e "${RED}protoc-gen-grpc-swift is not installed. Please run: brew install grpc-swift${NC}"
    exit 1
fi

# Generate Swift files from proto
echo -e "${GREEN}Generating Swift files from proto...${NC}"

# Find all proto files
PROTO_FILES=$(find "$BACKEND_PROTO_DIR" -name "*.proto" -not -path "*/google/*")

# Generate Swift code for each proto file
for proto_file in $PROTO_FILES; do
    echo -e "Processing: $proto_file"
    
    protoc \
        --proto_path="$BACKEND_PROTO_DIR" \
        --proto_path="$PROJECT_ROOT/Backend/include" \
        --swift_out="$OUTPUT_DIR" \
        --swift_opt=Visibility=Public \
        --grpc-swift_out="$OUTPUT_DIR" \
        --grpc-swift_opt=Visibility=Public \
        --grpc-swift_opt=Client=true \
        --grpc-swift_opt=Server=false \
        "$proto_file"
done

echo -e "${GREEN}Proto generation complete!${NC}"
echo -e "${GREEN}Generated files are in: $OUTPUT_DIR${NC}"

# Create a module map for the generated files
cat > "$OUTPUT_DIR/module.modulemap" << EOF
module ClassNotesGRPC {
    header "classnotes.v1.pb.h"
    header "classnotes.v1.grpc.swift.h"
    export *
}
EOF

echo -e "${GREEN}Created module map${NC}"

# Create a bridging header if needed
cat > "$OUTPUT_DIR/ClassNotesGRPC-Bridging-Header.h" << EOF
//
//  ClassNotesGRPC-Bridging-Header.h
//  ClassNotes
//

#ifndef ClassNotesGRPC_Bridging_Header_h
#define ClassNotesGRPC_Bridging_Header_h

// Import any Objective-C headers here if needed

#endif /* ClassNotesGRPC_Bridging_Header_h */
EOF

echo -e "${GREEN}All done! Generated files are in: $OUTPUT_DIR${NC}" 