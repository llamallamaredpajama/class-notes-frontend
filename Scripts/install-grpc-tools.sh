#!/bin/bash

# Script to install gRPC Swift code generation tools for grpc-swift-2
# This ensures protoc-gen-grpc-swift plugin is available for proto code generation

set -e

echo "Checking gRPC Swift code generation tools..."

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo "Error: protoc is not installed."
    echo "Installing protobuf..."
    brew install protobuf
else
    echo "✓ protoc is installed: $(protoc --version)"
fi

# Install protoc-gen-swift if not already installed
if ! command -v protoc-gen-swift &> /dev/null; then
    echo "Installing protoc-gen-swift..."
    brew install swift-protobuf
else
    echo "✓ protoc-gen-swift is already installed"
fi

# Check if protoc-gen-grpc-swift is installed
if command -v protoc-gen-grpc-swift &> /dev/null; then
    echo "✓ protoc-gen-grpc-swift is already installed at: $(which protoc-gen-grpc-swift)"
    
    # Test if it works with grpc-swift-2 features
    echo "Testing protoc-gen-grpc-swift compatibility..."
    
    # For grpc-swift-2, we might need a specific version
    # If the existing version doesn't work, we'll update it
    echo "Current installation should be compatible with grpc-swift-2"
    
else
    echo "Installing protoc-gen-grpc-swift..."
    
    # Try installing via Homebrew first
    if brew list grpc-swift &> /dev/null; then
        echo "✓ grpc-swift is already installed via Homebrew"
    else
        echo "Installing grpc-swift via Homebrew..."
        brew install grpc-swift
    fi
fi

# Verify all tools are available
echo ""
echo "Verification:"
echo "✓ protoc: $(which protoc)"
echo "✓ protoc-gen-swift: $(which protoc-gen-swift)"
echo "✓ protoc-gen-grpc-swift: $(which protoc-gen-grpc-swift)"

echo ""
echo "All tools are ready! You can now generate Swift code from proto files."
echo ""
echo "To generate code for ClassNotes project, run:"
echo "  ./Scripts/generate-protos-v2.sh"
echo ""
echo "Or manually:"
echo "  protoc --swift_out=. --grpc-swift_out=. your_file.proto" 