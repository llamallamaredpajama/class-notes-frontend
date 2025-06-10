#!/bin/bash

# Quick Start Script for Class Notes Frontend Development
# This script helps developers get started with the hybrid Cursor + Xcode workflow

echo "🚀 Class Notes Frontend - Quick Start"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -f "class-notes-frontend.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the class-notes-frontend directory"
    exit 1
fi

echo "✅ Found Xcode project"
echo ""

# Display available commands
echo "📋 Available Commands:"
echo "----------------------"
echo "1. ./Scripts/xcode-build.sh     - Build the project from command line"
echo "2. ./Scripts/run-tests.sh       - Run all tests"
echo "3. open .                       - Open project in Cursor"
echo "4. open *.xcodeproj             - Open project in Xcode"
echo ""

echo "🛠️  Development Workflow:"
echo "------------------------"
echo "1. Use Cursor for coding (already configured with .cursor/settings.json)"
echo "2. Use DebugView.swift for quick component testing"
echo "3. Run builds with Scripts/xcode-build.sh"
echo "4. View logs with: log stream --predicate 'subsystem == \"com.classnotes.app\"'"
echo ""

echo "🔍 Debug Features:"
echo "------------------"
echo "- PreviewHelpers.swift: Mock data and preview extensions"
echo "- DebugView.swift: Component gallery and testing"
echo "- DebugOverlay.swift: Visual debugging tools"
echo "- Logger+Extensions.swift: Structured logging"
echo ""

echo "📚 Documentation:"
echo "-----------------"
echo "- ARCHITECTURE.md: Project structure and patterns"
echo "- README.md: General project information"
echo ""

# Ask if user wants to open in Cursor
read -p "Would you like to open the project in Cursor now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening in Cursor..."
    cursor .
fi

echo ""
echo "✨ Happy coding!" 