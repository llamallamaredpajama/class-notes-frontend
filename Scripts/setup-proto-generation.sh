#!/bin/bash

# Setup script for proto generation with gRPC-Swift v2
# This downloads and installs the necessary protoc plugins

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up gRPC-Swift v2 Proto Generation${NC}"

# Create plugin directory
PLUGIN_DIR="$HOME/.local/bin"
mkdir -p "$PLUGIN_DIR"

# Check if protoc is installed
if ! command -v protoc >/dev/null 2>&1; then
    echo -e "${RED}Error: protoc is not installed${NC}"
    echo "Install protoc using: brew install protobuf"
    exit 1
fi

echo -e "\n${BLUE}Installing protoc plugins...${NC}"

# Download protoc-gen-swift from swift-protobuf
if [ ! -f "$PLUGIN_DIR/protoc-gen-swift" ]; then
    echo -e "${YELLOW}Downloading protoc-gen-swift...${NC}"
    
    # Create a temporary directory for building
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone swift-protobuf
    git clone --depth 1 --branch 1.30.0 https://github.com/apple/swift-protobuf.git
    cd swift-protobuf
    
    # Build the plugin
    swift build -c release --product protoc-gen-swift
    
    # Copy to plugin directory
    cp .build/release/protoc-gen-swift "$PLUGIN_DIR/"
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}protoc-gen-swift installed${NC}"
else
    echo -e "${GREEN}protoc-gen-swift already installed${NC}"
fi

# Download protoc-gen-grpc-swift from grpc-swift-protobuf
if [ ! -f "$PLUGIN_DIR/protoc-gen-grpc-swift" ]; then
    echo -e "${YELLOW}Downloading protoc-gen-grpc-swift v2...${NC}"
    
    # Create a temporary directory for building
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone grpc-swift-protobuf
    git clone --depth 1 --branch 2.0.0 https://github.com/grpc/grpc-swift-protobuf.git
    cd grpc-swift-protobuf
    
    # Build the plugin
    swift build -c release --product protoc-gen-grpc-swift
    
    # Copy to plugin directory
    cp .build/release/protoc-gen-grpc-swift "$PLUGIN_DIR/"
    
    # Clean up
    cd /
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}protoc-gen-grpc-swift installed${NC}"
else
    echo -e "${GREEN}protoc-gen-grpc-swift already installed${NC}"
fi

# Make plugins executable
chmod +x "$PLUGIN_DIR/protoc-gen-swift"
chmod +x "$PLUGIN_DIR/protoc-gen-grpc-swift"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$PLUGIN_DIR:"* ]]; then
    echo -e "\n${YELLOW}Add this to your shell profile (.zshrc or .bashrc):${NC}"
    echo "export PATH=\"\$PATH:$PLUGIN_DIR\""
fi

echo -e "\n${GREEN}Setup complete!${NC}"
echo "Plugins installed to: $PLUGIN_DIR"
echo ""
echo "Next steps:"
echo "1. Add $PLUGIN_DIR to your PATH (see above)"
echo "2. Run ./Scripts/generate-protos-direct.sh to generate proto files" 