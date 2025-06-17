#!/bin/bash

# install-grpc-tools.sh
# Script to install grpc-swift-2 code generation tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing gRPC Swift 2 code generation tools...${NC}"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew is not installed. Please install Homebrew first.${NC}"
    echo "Visit: https://brew.sh"
    exit 1
fi

# Install protobuf compiler if not already installed
if ! command -v protoc &> /dev/null; then
    echo -e "${YELLOW}Installing protobuf...${NC}"
    brew install protobuf
else
    echo -e "${GREEN}protobuf is already installed${NC}"
fi

# Install swift-protobuf if not already installed
if ! command -v protoc-gen-swift &> /dev/null; then
    echo -e "${YELLOW}Installing swift-protobuf...${NC}"
    brew install swift-protobuf
else
    echo -e "${GREEN}swift-protobuf is already installed${NC}"
fi

# Clone and build grpc-swift-protobuf plugin
echo -e "${YELLOW}Building grpc-swift-protobuf plugin...${NC}"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone the repository
echo -e "${GREEN}Cloning grpc-swift-protobuf...${NC}"
git clone https://github.com/grpc/grpc-swift-protobuf.git
cd grpc-swift-protobuf

# Build the plugin
echo -e "${GREEN}Building protoc-gen-grpc-swift...${NC}"
swift build -c release --product protoc-gen-grpc-swift

# Copy to /usr/local/bin
echo -e "${GREEN}Installing protoc-gen-grpc-swift...${NC}"
sudo cp .build/release/protoc-gen-grpc-swift /usr/local/bin/

# Clean up
cd ~
rm -rf "$TEMP_DIR"

# Verify installation
echo -e "${GREEN}Verifying installation...${NC}"
echo -e "protoc version: $(protoc --version)"
echo -e "swift-protobuf version: $(protoc-gen-swift --version)"

if command -v protoc-gen-grpc-swift &> /dev/null; then
    echo -e "${GREEN}protoc-gen-grpc-swift installed successfully${NC}"
else
    echo -e "${RED}protoc-gen-grpc-swift installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}All tools installed successfully!${NC}"
echo -e "${GREEN}You can now run the proto generation script.${NC}"

# Make the script executable
chmod +x "$0" 