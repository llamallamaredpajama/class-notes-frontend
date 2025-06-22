#!/bin/bash
# validate-packages.sh - Ensure only gRPC Swift v2 packages are used

set -e

echo "🔍 Validating Swift Package Dependencies..."

PROJECT_DIR="$(dirname "$0")/.."
PBXPROJ_FILE="$PROJECT_DIR/class-notes-frontend.xcodeproj/project.pbxproj"
PACKAGE_RESOLVED="$PROJECT_DIR/class-notes-frontend.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

validate_pbxproj() {
    echo "📁 Checking project.pbxproj for package conflicts..."
    
    # Check for old gRPC v1 packages (excluding comments)
    if grep -v "^[[:space:]]*#\|^[[:space:]]*//\|^[[:space:]]*\*" "$PBXPROJ_FILE" | grep -q "grpc-swift-nio-transport.*1\."; then
        echo -e "${RED}❌ ERROR: Found reference to old grpc-swift-nio-transport v1 package!${NC}"
        echo "   This is a gRPC v1 package that should not be used."
        echo "   Use grpc-swift-nio-transport v2+ or transport from grpc-swift-2 instead."
        return 1
    fi

    # Note: grpc-swift-protobuf v2.x is REQUIRED for protobuf support in gRPC Swift v2
    # We don't check for it here since it's a valid v2 package

    # Check for the old main grpc-swift repo (not grpc-swift-2)
    if grep -v "^[[:space:]]*#\|^[[:space:]]*//\|^[[:space:]]*\*" "$PBXPROJ_FILE" | grep "grpc-swift" | grep -v "grpc-swift-2\|grpc-swift-nio-transport"; then
        echo -e "${RED}❌ ERROR: Found reference to old grpc-swift v1 package!${NC}"
        echo "   Use grpc-swift-2 instead."
        return 1
    fi

    # Check for correct gRPC v2 package
    if ! grep -q "grpc-swift-2" "$PBXPROJ_FILE"; then
        echo -e "${RED}❌ ERROR: grpc-swift-2 package not found!${NC}"
        echo "   The project should use grpc-swift-2 for all gRPC functionality."
        return 1
    fi

    echo -e "${GREEN}✅ project.pbxproj validation passed${NC}"
    return 0
}

validate_package_resolved() {
    if [ ! -f "$PACKAGE_RESOLVED" ]; then
        echo -e "${YELLOW}⚠️  Package.resolved not found (this is OK for fresh checkouts)${NC}"
        return 0
    fi

    echo "📦 Checking Package.resolved..."
    
    # Check for old gRPC packages
    if grep -q '"grpc-swift-nio-transport"' "$PACKAGE_RESOLVED"; then
        VERSION=$(grep -A 10 '"grpc-swift-nio-transport"' "$PACKAGE_RESOLVED" | grep '"version"' | head -1 | sed 's/.*"version" : "\([^"]*\)".*/\1/')
        if [[ "$VERSION" =~ ^1\. ]]; then
            echo -e "${RED}❌ ERROR: Package.resolved contains grpc-swift-nio-transport v1.x!${NC}"
            echo "   Found version: $VERSION"
            echo "   This should be v2.x+ or removed entirely."
            return 1
        fi
    fi

    # Check for grpc-swift-protobuf - v2.x is REQUIRED for protobuf support
    if grep -q '"grpc-swift-protobuf"' "$PACKAGE_RESOLVED"; then
        VERSION=$(grep -A 10 '"grpc-swift-protobuf"' "$PACKAGE_RESOLVED" | grep '"version"' | head -1 | sed 's/.*"version" : "\([^"]*\)".*/\1/')
        if [[ "$VERSION" =~ ^1\. ]]; then
            echo -e "${RED}❌ ERROR: Package.resolved contains grpc-swift-protobuf v1.x!${NC}"
            echo "   Found version: $VERSION"
            echo "   This should be v2.x for gRPC Swift v2."
            return 1
        else
            echo -e "${GREEN}✅ Found grpc-swift-protobuf v$VERSION (required for protobuf support)${NC}"
        fi
    fi

    if grep -q '"grpc-swift"' "$PACKAGE_RESOLVED" && ! grep -q '"grpc-swift-2"' "$PACKAGE_RESOLVED"; then
        echo -e "${RED}❌ ERROR: Package.resolved contains old grpc-swift v1 package!${NC}"
        echo "   Use grpc-swift-2 instead."
        return 1
    fi

    echo -e "${GREEN}✅ Package.resolved validation passed${NC}"
    return 0
}

validate_imports() {
    echo "📄 Checking Swift files for problematic imports..."
    
    SWIFT_FILES=$(find "$PROJECT_DIR/class-notes-frontend" -name "*.swift" -type f)
    BAD_IMPORTS=()
    INFO_IMPORTS=()
    
    while IFS= read -r file; do
        # Check for definitely bad imports (old gRPC v1)
        if grep -q "^import GRPC$" "$file"; then
            BAD_IMPORTS+=("$file")
        # Check for informational imports (valid but worth noting)
        elif grep -q "import GRPCProtobuf\|import GRPCNIOTransportHTTP2\|import NIOCore\|import NIOPosix" "$file"; then
            INFO_IMPORTS+=("$file")
        fi
    done <<< "$SWIFT_FILES"
    
    if [ ${#BAD_IMPORTS[@]} -gt 0 ]; then
        echo -e "${RED}❌ Found problematic v1 imports:${NC}"
        for file in "${BAD_IMPORTS[@]}"; do
            echo "   $file"
            grep -n "^import GRPC$" "$file" || true
        done
        echo "   These imports are from gRPC Swift v1 and must be updated!"
    elif [ ${#INFO_IMPORTS[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ All imports are valid for gRPC Swift v2${NC}"
        echo -e "${BLUE}ℹ️  These files use v2 modules (this is correct):${NC}"
        echo "   • GRPCProtobuf - v2 protobuf serialization"
        echo "   • GRPCNIOTransportHTTP2 - v2 transport layer"
        echo "   • NIOCore/NIOPosix - async I/O support"
        echo "   Found in ${#INFO_IMPORTS[@]} files"
    else
        echo -e "${GREEN}✅ No import issues found${NC}"
    fi
}

check_derived_data() {
    echo "🗂️  Checking for stale derived data..."
    
    DERIVED_DATA_DIRS=$(find ~/Library/Developer/Xcode/DerivedData -name "class-notes-frontend-*" -type d 2>/dev/null || true)
    
    if [ -n "$DERIVED_DATA_DIRS" ]; then
        echo -e "${YELLOW}⚠️  Found derived data directories:${NC}"
        echo "$DERIVED_DATA_DIRS"
        echo "   Consider running: rm -rf ~/Library/Developer/Xcode/DerivedData/class-notes-frontend-*"
    else
        echo -e "${GREEN}✅ No stale derived data found${NC}"
    fi
}

main() {
    echo "Starting comprehensive gRPC package validation..."
    echo "======================================================="
    
    local exit_code=0
    
    if ! validate_pbxproj; then
        exit_code=1
    fi
    
    if ! validate_package_resolved; then
        exit_code=1
    fi
    
    validate_imports
    check_derived_data
    
    echo "======================================================="
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}🎉 All package validations passed!${NC}"
        echo "Your project is properly configured for gRPC Swift v2."
    else
        echo -e "${RED}💥 Package validation failed!${NC}"
        echo ""
        echo "To fix package conflicts:"
        echo "1. Close Xcode"
        echo "2. Run: ./Scripts/clean-packages.sh"
        echo "3. Open Xcode and reset package caches"
        echo "4. Wait for package resolution"
        echo "5. Re-run this validation"
    fi
    
    exit $exit_code
}

main "$@" 