#!/bin/bash
# clean-packages.sh - Complete package cleanup script for gRPC Swift conflicts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(dirname "$0")/.."

echo -e "${BLUE}🧹 Starting comprehensive Swift Package cleanup...${NC}"
echo "This will remove all cached package data to resolve conflicts."
echo ""

ask_confirmation() {
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
}

cleanup_xcode_derived_data() {
    echo -e "${YELLOW}🗑️  Removing Xcode DerivedData...${NC}"
    
    # Remove project-specific derived data
    if ls ~/Library/Developer/Xcode/DerivedData/class-notes-frontend-* 1> /dev/null 2>&1; then
        rm -rf ~/Library/Developer/Xcode/DerivedData/class-notes-frontend-*
        echo "   ✅ Removed class-notes-frontend DerivedData"
    else
        echo "   ℹ️  No class-notes-frontend DerivedData found"
    fi
    
    # Optionally remove all derived data (more aggressive)
    echo "Remove ALL DerivedData? (This affects all Xcode projects)"
    read -p "(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
        echo "   ✅ Removed all DerivedData"
    fi
}

cleanup_swiftpm_caches() {
    echo -e "${YELLOW}📦 Removing Swift Package Manager caches...${NC}"
    
    # Remove global SPM cache
    if [ -d ~/Library/Caches/org.swift.swiftpm ]; then
        rm -rf ~/Library/Caches/org.swift.swiftpm
        echo "   ✅ Removed global SPM cache"
    else
        echo "   ℹ️  No global SPM cache found"
    fi
    
    # Remove additional SPM cache locations
    if [ -d ~/Library/Caches/com.apple.dt.Xcode/SharedPackageCache ]; then
        rm -rf ~/Library/Caches/com.apple.dt.Xcode/SharedPackageCache
        echo "   ✅ Removed Xcode shared package cache"
    else
        echo "   ℹ️  No Xcode shared package cache found"
    fi
}

cleanup_local_swiftpm() {
    echo -e "${YELLOW}📁 Removing local .swiftpm directories...${NC}"
    
    # Remove .swiftpm in project directory
    if [ -d "$PROJECT_DIR/.swiftpm" ]; then
        rm -rf "$PROJECT_DIR/.swiftpm"
        echo "   ✅ Removed project .swiftpm directory"
    else
        echo "   ℹ️  No project .swiftpm directory found"
    fi
    
    # Remove .swiftpm in Xcode project
    if [ -d "$PROJECT_DIR/class-notes-frontend.xcodeproj/.swiftpm" ]; then
        rm -rf "$PROJECT_DIR/class-notes-frontend.xcodeproj/.swiftpm"
        echo "   ✅ Removed Xcode project .swiftpm directory"
    else
        echo "   ℹ️  No Xcode project .swiftpm directory found"
    fi
}

cleanup_package_resolved() {
    echo -e "${YELLOW}🔗 Removing Package.resolved files...${NC}"
    
    PACKAGE_RESOLVED="$PROJECT_DIR/class-notes-frontend.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    
    if [ -f "$PACKAGE_RESOLVED" ]; then
        echo "   Found Package.resolved with these packages:"
        if command -v jq >/dev/null 2>&1; then
            jq -r '.pins[].identity' "$PACKAGE_RESOLVED" 2>/dev/null | sed 's/^/     - /' || cat "$PACKAGE_RESOLVED" | grep '"identity"' | sed 's/.*"identity" : "\([^"]*\)".*/     - \1/'
        else
            grep '"identity"' "$PACKAGE_RESOLVED" | sed 's/.*"identity" : "\([^"]*\)".*/     - \1/'
        fi
        
        echo ""
        echo "Remove Package.resolved? This will force fresh package resolution."
        read -p "(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup before removing
            cp "$PACKAGE_RESOLVED" "$PACKAGE_RESOLVED.backup.$(date +%Y%m%d_%H%M%S)"
            rm "$PACKAGE_RESOLVED"
            echo "   ✅ Removed Package.resolved (backup created)"
        else
            echo "   ⏭️  Keeping existing Package.resolved"
        fi
    else
        echo "   ℹ️  No Package.resolved found"
    fi
}

cleanup_xcode_workspaces() {
    echo -e "${YELLOW}💼 Cleaning Xcode workspace data...${NC}"
    
    # Remove workspace state
    WORKSPACE_DATA="$PROJECT_DIR/class-notes-frontend.xcodeproj/project.xcworkspace/xcuserdata"
    if [ -d "$WORKSPACE_DATA" ]; then
        rm -rf "$WORKSPACE_DATA"
        echo "   ✅ Removed workspace user data"
    else
        echo "   ℹ️  No workspace user data found"
    fi
    
    # Remove user-specific project data
    USER_DATA="$PROJECT_DIR/class-notes-frontend.xcodeproj/xcuserdata"
    if [ -d "$USER_DATA" ]; then
        rm -rf "$USER_DATA"
        echo "   ✅ Removed project user data"
    else
        echo "   ℹ️  No project user data found"
    fi
}

validate_project_state() {
    echo -e "${BLUE}🔍 Validating project state...${NC}"
    
    # Check if validation script exists and run it
    if [ -f "$PROJECT_DIR/Scripts/validate-packages.sh" ]; then
        echo "   Running package validation..."
        if bash "$PROJECT_DIR/Scripts/validate-packages.sh"; then
            echo -e "   ${GREEN}✅ Project validation passed${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Project validation found issues${NC}"
            echo "   These may be resolved after Xcode re-resolves packages"
        fi
    else
        echo "   ℹ️  Package validation script not found"
    fi
}

main() {
    echo "This script will clean the following:"
    echo "• Xcode DerivedData"
    echo "• Swift Package Manager caches"
    echo "• Local .swiftpm directories"
    echo "• Package.resolved files"
    echo "• Xcode workspace data"
    echo ""
    
    ask_confirmation
    
    cleanup_xcode_derived_data
    cleanup_swiftpm_caches
    cleanup_local_swiftpm
    cleanup_package_resolved
    cleanup_xcode_workspaces
    
    echo ""
    echo -e "${GREEN}🎉 Package cleanup completed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open Xcode"
    echo "2. Go to File → Packages → Reset Package Caches"
    echo "3. Wait for package resolution to complete"
    echo "4. Build your project"
    echo "5. Run: ./Scripts/validate-packages.sh"
    echo ""
    echo -e "${YELLOW}Note: First build after cleanup may take longer as packages are re-downloaded${NC}"
    
    validate_project_state
}

main "$@" 