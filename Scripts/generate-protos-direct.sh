#!/bin/bash

# Direct Proto Generation for gRPC-Swift v2
# This script generates Swift protobuf and gRPC code directly without Xcode involvement

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

echo -e "${GREEN}Direct gRPC-Swift v2 Proto Generation${NC}"
echo "Frontend directory: $FRONTEND_DIR"
echo "DevOps directory: $DEVOPS_DIR"

# Check if protoc is installed
if ! command -v protoc >/dev/null 2>&1; then
    echo -e "${RED}Error: protoc is not installed${NC}"
    echo "Install protoc using: brew install protobuf"
    exit 1
fi

# Check if plugins are available
if ! command -v protoc-gen-swift >/dev/null 2>&1; then
    echo -e "${RED}Error: protoc-gen-swift not found${NC}"
    echo "Install using: brew install swift-protobuf"
    exit 1
fi

if ! command -v protoc-gen-grpc-swift >/dev/null 2>&1; then
    echo -e "${RED}Error: protoc-gen-grpc-swift not found${NC}"
    echo "Install using: brew install grpc-swift"
    exit 1
fi

echo -e "${GREEN}Found protoc plugins:${NC}"
echo "  protoc-gen-swift: $(which protoc-gen-swift)"
echo "  protoc-gen-grpc-swift: $(which protoc-gen-grpc-swift)"

# Create output directory OUTSIDE of the main project
OUTPUT_DIR="$FRONTEND_DIR/GeneratedProtos"
mkdir -p "$OUTPUT_DIR"

# Clean existing generated files
echo -e "\n${YELLOW}Cleaning existing generated files...${NC}"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Change to proto directory
cd "$DEVOPS_DIR/proto-management"

echo -e "\n${GREEN}Generating Swift protobuf files...${NC}"

# Generate protobuf files
protoc \
    --swift_out="$OUTPUT_DIR" \
    --swift_opt=Visibility=Public \
    --swift_opt=FileNaming=DropPath \
    -I proto \
    proto/classnotes/v1/classnotes_service.proto

echo -e "\n${GREEN}Generating gRPC client code...${NC}"

# Generate gRPC files with v2 options
protoc \
    --grpc-swift_out="$OUTPUT_DIR" \
    --grpc-swift_opt=Visibility=Public \
    --grpc-swift_opt=Client=true \
    --grpc-swift_opt=Server=false \
    --grpc-swift_opt=FileNaming=DropPath \
    -I proto \
    proto/classnotes/v1/classnotes_service.proto

# Count generated files
GENERATED_COUNT=$(find "$OUTPUT_DIR" -name "*.swift" | wc -l | tr -d ' ')

if [ "$GENERATED_COUNT" -eq "0" ]; then
    echo -e "${RED}Error: No files were generated${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully generated $GENERATED_COUNT Swift files${NC}"

# List generated files
echo -e "\n${BLUE}Generated files:${NC}"
ls -la "$OUTPUT_DIR"

# Create a simple Package.swift for the generated code
echo -e "\n${YELLOW}Creating Swift Package for generated code...${NC}"

cat > "$OUTPUT_DIR/Package.swift" << EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeneratedProtos",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "GeneratedProtos",
            targets: ["GeneratedProtos"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "GeneratedProtos",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf")
            ],
            path: "Sources"
        )
    ]
)
EOF

# Move generated files to proper package structure
mkdir -p "$OUTPUT_DIR/Sources/GeneratedProtos"
mv "$OUTPUT_DIR"/*.swift "$OUTPUT_DIR/Sources/GeneratedProtos/" 2>/dev/null || true

# Create usage instructions
cat > "$OUTPUT_DIR/README.md" << EOF
# Generated Proto Files

This directory contains the generated protobuf and gRPC code for ClassNotes.

## Generated Files

- \`classnotes_service.pb.swift\` - Protocol buffer message definitions
- \`classnotes_service.grpc.swift\` - gRPC client code

## Usage in Xcode

### As a Local Swift Package (Recommended)

1. In Xcode, go to File → Add Package Dependencies
2. Click "Add Local..."
3. Navigate to and select the GeneratedProtos folder
4. Click "Add Package"
5. Import in your code: \`import GeneratedProtos\`

### Direct File Import (Not Recommended)

1. Drag the Sources folder into your Xcode project
2. Make sure "Copy items if needed" is UNCHECKED
3. Add to your target

## Important Notes

- These files are generated OUTSIDE of Xcode to avoid build-time conflicts
- Do NOT add proto generation as a build phase in Xcode
- To regenerate, run: \`./Scripts/generate-protos-direct.sh\`
- The generated code uses gRPC-Swift v2 APIs correctly
EOF

echo -e "\n${GREEN}Proto generation complete!${NC}"
echo ""
echo "Generated Swift Package at: $OUTPUT_DIR"
echo ""
echo -e "${YELLOW}IMPORTANT: Use as a local Swift Package in Xcode${NC}"
echo "1. File → Add Package Dependencies"
echo "2. Add Local... → Select GeneratedProtos folder"
echo "3. Import GeneratedProtos in your code"
echo ""
echo "This approach avoids all Xcode compilation issues!" 