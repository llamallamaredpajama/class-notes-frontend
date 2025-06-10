#!/bin/bash

# Script to build the project from command line while working in Cursor
# This allows building without switching to Xcode

echo "🔨 Building class-notes-frontend..."

# Activate Xcode (optional - comment out if you prefer to build in background)
osascript -e 'tell application "Xcode" to activate'

# Build the project
xcodebuild -project class-notes-frontend.xcodeproj \
           -scheme class-notes-frontend \
           -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' \
           build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed!"
    exit 1
fi 