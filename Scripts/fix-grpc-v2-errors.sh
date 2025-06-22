#!/bin/bash
#
# fix-grpc-v2-errors.sh
# Script to fix gRPC-Swift v2 errors in the Class Notes frontend
#

set -e

echo "🔧 Starting gRPC-Swift v2 error fix process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/../class-notes-frontend" && pwd )"

# Check if we're in the right structure
if [ ! -f "$PROJECT_DIR/buf.gen.yaml" ]; then
    echo -e "${RED}Error: buf.gen.yaml not found in $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Step 1: Clean derived data
echo -e "${YELLOW}Step 1: Cleaning DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo -e "${GREEN}✓ DerivedData cleaned${NC}"

# Step 2: Remove old generated files
echo -e "${YELLOW}Step 2: Removing old generated proto files...${NC}"
rm -rf ClassNotes/Core/Networking/gRPC/Generated/*
echo -e "${GREEN}✓ Old proto files removed${NC}"

# Step 3: Update buf.gen.yaml if needed
echo -e "${YELLOW}Step 3: Checking buf.gen.yaml...${NC}"
if ! grep -q "buf.build/grpc/swift:v2" buf.gen.yaml; then
    echo "Updating buf.gen.yaml to use gRPC-Swift v2 plugin..."
    cat > buf.gen.yaml << 'EOF'
version: v2
managed:
  enabled: true
  go_package_prefix:
    default: github.com/yourdomain/classnotes
plugins:
  - plugin: buf.build/grpc/swift:v2.0.0
    out: ClassNotes/Core/Networking/gRPC/Generated
    opt:
      - Visibility=Public
      - Server=false
      - Client=true
      - UseAccessLevelOnImports=true
  - plugin: buf.build/apple/swift
    out: ClassNotes/Core/Networking/gRPC/Generated
    opt:
      - Visibility=Public
      - UseAccessLevelOnImports=true
EOF
    echo -e "${GREEN}✓ buf.gen.yaml updated${NC}"
else
    echo -e "${GREEN}✓ buf.gen.yaml already configured for v2${NC}"
fi

# Step 4: Regenerate proto files
echo -e "${YELLOW}Step 4: Regenerating proto files...${NC}"
if command -v buf &> /dev/null; then
    buf generate
    echo -e "${GREEN}✓ Proto files regenerated${NC}"
else
    echo -e "${RED}Warning: buf CLI not found. Please install it and run 'buf generate' manually.${NC}"
    echo "Install with: brew install bufbuild/buf/buf"
fi

# Step 5: Create Package.swift if it doesn't exist
echo -e "${YELLOW}Step 5: Checking Package.swift...${NC}"
if [ ! -f "Package.swift" ]; then
    echo "Creating Package.swift for dependency management..."
    cat > Package.swift << 'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClassNotesFrontend",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift-2", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "8.0.0"),
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.4")
    ],
    targets: [
        .target(
            name: "ClassNotes",
            dependencies: [
                .product(name: "GRPCCore", package: "grpc-swift"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift"),
                .product(name: "GRPCProtobuf", package: "grpc-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAppCheck", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "WhisperKit", package: "WhisperKit")
            ]
        )
    ]
)
EOF
    echo -e "${GREEN}✓ Package.swift created${NC}"
else
    echo -e "${GREEN}✓ Package.swift already exists${NC}"
fi

# Step 6: Instructions for Xcode
echo -e "${YELLOW}Step 6: Manual steps required in Xcode:${NC}"
echo "1. Open the project in Xcode"
echo "2. Select the project in the navigator"
echo "3. Go to Package Dependencies tab"
echo "4. Remove any existing gRPC-Swift packages"
echo "5. Add package: https://github.com/grpc/grpc-swift-2 (version 2.0.0+)"
echo "6. Add these products to your target:"
echo "   - GRPCCore"
echo "   - GRPCNIOTransportHTTP2"
echo "   - GRPCProtobuf"
echo "7. Clean build folder (Shift+Cmd+K)"
echo "8. Build the project (Cmd+B)"

echo -e "\n${GREEN}✅ Automated steps completed!${NC}"
echo -e "${YELLOW}Please complete the manual steps in Xcode to finish the fix.${NC}"

# Optional: Open Xcode
read -p "Would you like to open the project in Xcode now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"
    open *.xcodeproj 2>/dev/null || open *.xcworkspace 2>/dev/null || echo "Could not find Xcode project"
fi 