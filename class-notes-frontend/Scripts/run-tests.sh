#!/bin/bash

# Script to run tests from command line while working in Cursor

echo "🧪 Running class-notes-frontend tests..."

# Run tests
xcodebuild test -project class-notes-frontend.xcodeproj \
                -scheme class-notes-frontend \
                -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
                -quiet

if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed!"
    exit 1
fi 