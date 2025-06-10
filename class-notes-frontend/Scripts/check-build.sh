#!/bin/bash

# Script to check for Swift compilation errors
# Works with Command Line Tools (doesn't require full Xcode)

echo "🔍 Checking Swift files for compilation errors..."
echo "================================================"

# Find all Swift files and compile them individually to check for errors
find class-notes-frontend -name "*.swift" -type f | while read -r file; do
    # Skip test files and generated files
    if [[ $file == *"Tests/"* ]] || [[ $file == *".build/"* ]]; then
        continue
    fi
    
    # Try to parse the Swift file
    swiftc -parse -sdk $(xcrun --show-sdk-path) "$file" 2>&1 | grep -E "(error:|warning:)" | while read -r line; do
        echo "❌ $file"
        echo "   $line"
    done
done

echo ""
echo "✅ Syntax check complete!"
echo ""
echo "Note: This only checks for syntax errors."
echo "For a full build, you need Xcode installed and use ./Scripts/xcode-build.sh" 