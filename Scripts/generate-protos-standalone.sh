#!/bin/bash

# Standalone Proto Generation for gRPC-Swift v2
# This script generates Swift protobuf and gRPC code outside of Xcode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FRONTEND_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
PROJECT_ROOT="/Users/jeremy/Code/class-notes-project"
DEVOPS_DIR="$PROJECT_ROOT/classnotes-devops"
PROTO_GEN_DIR="$FRONTEND_DIR/ProtoGeneration"

echo -e "${GREEN}Standalone gRPC-Swift v2 Proto Generation${NC}"
echo "Frontend directory: $FRONTEND_DIR"
echo "DevOps directory: $DEVOPS_DIR"
echo "Proto generation directory: $PROTO_GEN_DIR"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo -e "\n${BLUE}Checking prerequisites...${NC}"

if ! command_exists protoc; then
    echo -e "${RED}Error: protoc is not installed${NC}"
    echo "Install protoc using: brew install protobuf"
    exit 1
fi

if ! command_exists swift; then
    echo -e "${RED}Error: Swift is not installed${NC}"
    exit 1
fi

# Install protoc plugins if needed
echo -e "\n${BLUE}Installing protoc plugins...${NC}"

# Create temporary directory for plugins
PLUGIN_DIR="$FRONTEND_DIR/.build/plugins"
mkdir -p "$PLUGIN_DIR"

# Build the plugins from the ProtoGeneration package
cd "$PROTO_GEN_DIR"

# First, resolve dependencies
echo -e "${YELLOW}Resolving Swift package dependencies...${NC}"
swift package resolve

# Build protoc-gen-swift if not exists
if [ ! -f "$PLUGIN_DIR/protoc-gen-swift" ]; then
    echo -e "${YELLOW}Building protoc-gen-swift...${NC}"
    swift build --product protoc-gen-swift \
        --package-path "$HOME/.swiftpm/Package/checkouts/swift-protobuf" \
        --configuration release
    
    # Find and copy the plugin
    SWIFT_PLUGIN=$(find "$HOME/.swiftpm/Package/checkouts/swift-protobuf/.build" -name "protoc-gen-swift" -type f | head -n 1)
    if [ -n "$SWIFT_PLUGIN" ]; then
        cp "$SWIFT_PLUGIN" "$PLUGIN_DIR/"
    fi
fi

# Build protoc-gen-grpc-swift from grpc-swift-protobuf
echo -e "${YELLOW}Building protoc-gen-grpc-swift v2...${NC}"
swift build --product protoc-gen-grpc-swift \
    --configuration release

# Find the built plugin
GRPC_PLUGIN=$(find .build -name "protoc-gen-grpc-swift" -type f | head -n 1)
if [ -z "$GRPC_PLUGIN" ]; then
    echo -e "${RED}Error: Could not find protoc-gen-grpc-swift plugin${NC}"
    exit 1
fi

cp "$GRPC_PLUGIN" "$PLUGIN_DIR/"

# Set plugin paths
export PATH="$PLUGIN_DIR:$PATH"

# Create output directory
OUTPUT_DIR="$PROTO_GEN_DIR/Sources/ClassNotesProtos"
mkdir -p "$OUTPUT_DIR"

# Clean existing generated files
echo -e "\n${YELLOW}Cleaning existing generated files...${NC}"
rm -rf "$OUTPUT_DIR"/*.swift

# Generate proto files
echo -e "\n${GREEN}Generating Swift protobuf and gRPC code...${NC}"

cd "$DEVOPS_DIR/proto-management"

# Generate protobuf files
protoc --plugin="$PLUGIN_DIR/protoc-gen-swift" \
       --swift_out="$OUTPUT_DIR" \
       --swift_opt=Visibility=Public \
       --swift_opt=FileNaming=DropPath \
       --swift_opt=SwiftProtobufModuleName=SwiftProtobuf \
       -I proto \
       proto/classnotes/v1/classnotes_service.proto

# Generate gRPC files
protoc --plugin="$PLUGIN_DIR/protoc-gen-grpc-swift" \
       --grpc-swift_out="$OUTPUT_DIR" \
       --grpc-swift_opt=Visibility=Public \
       --grpc-swift_opt=Client=true \
       --grpc-swift_opt=Server=false \
       --grpc-swift_opt=FileNaming=DropPath \
       --grpc-swift_opt=SwiftProtobufModuleName=SwiftProtobuf \
       --grpc-swift_opt=UseAccessLevelOnImports=true \
       -I proto \
       proto/classnotes/v1/classnotes_service.proto

# Count generated files
GENERATED_COUNT=$(find "$OUTPUT_DIR" -name "*.swift" | wc -l | tr -d ' ')

if [ "$GENERATED_COUNT" -eq "0" ]; then
    echo -e "${RED}Error: No files were generated${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully generated $GENERATED_COUNT Swift files${NC}"

# Create a module map if needed
echo -e "\n${YELLOW}Creating module structure...${NC}"

# Create export file
cat > "$OUTPUT_DIR/Exports.swift" << EOF
// Re-export all generated types
@_exported import SwiftProtobuf
@_exported import GRPCCore
@_exported import GRPCProtobuf
EOF

# Create README for the generated module
cat > "$PROTO_GEN_DIR/README.md" << EOF
# ClassNotes Proto Generation

This module contains the generated protobuf and gRPC code for the ClassNotes project.

## Generated Files

- \`classnotes_service.pb.swift\` - Protocol buffer message definitions
- \`classnotes_service.grpc.swift\` - gRPC client code

## Usage

To use this module in your Xcode project:

1. Add the ProtoGeneration folder as a local Swift Package dependency
2. Import the module: \`import ClassNotesProtos\`

## Regeneration

To regenerate the proto files, run:
\`\`\`bash
./Scripts/generate-protos-standalone.sh
\`\`\`

This runs outside of Xcode to avoid build-time regeneration issues.
EOF

echo -e "\n${GREEN}Proto generation complete!${NC}"
echo ""
echo "Generated files are in: $OUTPUT_DIR"
echo ""
echo "To use in your Xcode project:"
echo "1. Add $PROTO_GEN_DIR as a local Swift Package dependency"
echo "2. Import ClassNotesProtos in your code"
echo ""
echo -e "${YELLOW}Note: This generation runs outside of Xcode to avoid build conflicts.${NC}" 