#!/bin/bash
# fix-grpc-v2-setup.sh - Fix gRPC-Swift v2 setup issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$SCRIPT_DIR/.."

echo -e "${BLUE}🔧 gRPC-Swift v2 Setup Fix${NC}"
echo "=================================="

# Step 1: Instructions for adding the missing package
echo -e "\n${YELLOW}📦 Step 1: Add Missing Package${NC}"
echo "The project is missing the required grpc-swift-protobuf package."
echo ""
echo "To fix this in Xcode:"
echo "1. Open class-notes-frontend.xcodeproj in Xcode"
echo "2. Go to File > Add Package Dependencies..."
echo "3. Enter this URL: https://github.com/grpc/grpc-swift-protobuf.git"
echo "4. Set the version rule to: Up to Next Major Version - 2.0.0"
echo "5. Click 'Add Package'"
echo "6. Select 'GRPCProtobuf' product and add it to your target"
echo ""
echo -e "${YELLOW}Press Enter after adding the package in Xcode...${NC}"
read -r

# Step 2: Regenerate proto files with buf
echo -e "\n${GREEN}🔄 Step 2: Regenerating Proto Files${NC}"
cd "$PROJECT_DIR"

# Use the correct comprehensive script from class-notes-frontend subdirectory
if [ -f "./class-notes-frontend/Scripts/generate-protos-v2.sh" ]; then
    echo "Running proto generation with buf..."
    ./class-notes-frontend/Scripts/generate-protos-v2.sh
elif [ -f "../Backend/buf.gen.yaml" ]; then
    echo "Using buf directly from Backend directory..."
    cd ../Backend
    buf generate proto --template ../Frontend/class-notes-frontend/buf.gen.yaml
    cd ../Frontend
else
    echo -e "${RED}Error: Could not find proto generation script or buf configuration${NC}"
    echo "Proto files location:"
    echo "  - Backend: /Users/jeremy/Code/class-notes-project/class-notes-backend/proto"
    echo "  - DevOps: /Users/jeremy/Code/class-notes-project/classnotes-devops/proto-management/proto"
    exit 1
fi

# Step 3: Clean derived data
echo -e "\n${GREEN}🧹 Step 3: Cleaning Derived Data${NC}"
echo "Removing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/class-notes-frontend-*

# Step 4: Run validation
echo -e "\n${GREEN}✅ Step 4: Running Validation${NC}"
if [ -f "./Scripts/validate-packages.sh" ]; then
    ./Scripts/validate-packages.sh
else
    echo -e "${YELLOW}Warning: validate-packages.sh not found${NC}"
fi

echo -e "\n${GREEN}✨ Setup fix complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Build the project in Xcode"
echo "2. If you see any remaining errors, check the imports in your service files"
echo "3. Ensure all service implementations use the v2 client pattern" 