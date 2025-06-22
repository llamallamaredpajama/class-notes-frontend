#!/bin/bash
echo "🧹 Deep Clean Xcode Build"
echo "========================"

# 1. Clean derived data
echo "1. Cleaning Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/

# 2. Clean SPM cache
echo "2. Cleaning Swift Package Manager cache..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build

# 3. Reset package cache in project
echo "3. Resetting package cache..."
cd class-notes-frontend.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/
rm -rf Package.resolved
cd -

echo ""
echo "✅ Clean complete!"
echo ""
echo "Now in Xcode:"
echo "1. Close Xcode completely"
echo "2. Open Xcode again"
echo "3. File → Packages → Reset Package Caches"
echo "4. File → Packages → Resolve Package Versions"
echo "5. Product → Clean Build Folder (⇧⌘K)"
echo "6. Product → Build (⌘B)"
