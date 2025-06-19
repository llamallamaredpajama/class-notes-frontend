# gRPC Swift Package Management Guidelines

## Overview

This document provides guidelines for the team to prevent recurring gRPC Swift v1/v2 package conflicts in the Class Notes iOS project.

## 🚨 Critical Rules

### 1. Package Dependencies

**✅ ONLY USE THESE PACKAGES:**
- `grpc-swift-2` (main gRPC Swift v2 package)
- `grpc-swift-nio-transport` v2.x+ (if needed for transport)

**❌ NEVER USE THESE PACKAGES:**
- `grpc-swift` (old v1 package)
- `grpc-swift-protobuf` (old v1 package)
- `grpc-swift-nio-transport` v1.x

### 2. Before Making Changes

**ALWAYS run validation before starting work:**
```bash
cd Frontend
./Scripts/validate-packages.sh
```

**If validation fails, clean packages first:**
```bash
./Scripts/clean-packages.sh
# Then open Xcode, reset package caches, and rebuild
```

### 3. Adding New Dependencies

1. **Research first**: Ensure any new package is compatible with gRPC Swift v2
2. **Check transitive dependencies**: New packages shouldn't pull in old gRPC v1 packages
3. **Validate after adding**: Run validation script after adding any new dependency
4. **Update team**: Notify team of new dependencies in pull request

## 🛠 Tools & Scripts

### Package Validation Script
```bash
./Scripts/validate-packages.sh
```
- Checks for conflicting gRPC packages
- Validates project.pbxproj and Package.resolved
- Scans Swift files for problematic imports
- **Run this before committing changes**

### Package Cleanup Script
```bash
./Scripts/clean-packages.sh
```
- Removes all cached package data
- Cleans DerivedData and SPM caches
- Forces fresh package resolution
- **Use when experiencing package conflicts**

### Pre-commit Hook
- Automatically runs before each commit
- Blocks commits that would introduce conflicts
- Validates staged changes for problematic packages

## 📋 Workflow Guidelines

### Daily Development

1. **Pull latest changes**
2. **Run validation** if you haven't worked on the project recently
3. **Work on your features**
4. **Run validation before committing**
5. **Commit and push**

### When Adding Dependencies

1. **Research compatibility** with gRPC Swift v2
2. **Add dependency in Xcode**
3. **Wait for resolution**
4. **Run validation script**
5. **Test build thoroughly**
6. **Commit with descriptive message**

### When Experiencing Issues

1. **Don't ignore warnings** from validation scripts
2. **Clean packages immediately** if conflicts detected
3. **Ask team for help** if unsure about fixes
4. **Update this document** if you discover new issues

## 🔧 Troubleshooting

### Common Issues

#### "Multiple references with same GUID"
```bash
# Close Xcode
./Scripts/clean-packages.sh
# Open Xcode, File → Packages → Reset Package Caches
# Wait for resolution, then build
```

#### "Package.resolved has conflicts"
```bash
# Remove Package.resolved and force fresh resolution
rm "class-notes-frontend.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
# Open Xcode, reset package caches
```

#### "Conflicting packages after pull"
```bash
# Clean everything and start fresh
./Scripts/clean-packages.sh
git pull  # Get latest changes
# Open Xcode, reset package caches
./Scripts/validate-packages.sh
```

### Import Guidelines

**✅ Correct imports for gRPC Swift v2:**
```swift
import GRPCCore
import GRPCNIOTransportHTTP2
import SwiftProtobuf
```

**❌ Avoid these imports:**
```swift
import GRPC              // Old v1 package
import NIOCore           // Use through GRPCCore instead
import NIOHTTP2          // Use through GRPCNIOTransportHTTP2 instead
```

## 🏗 Project Structure

### Key Files to Monitor

- `class-notes-frontend.xcodeproj/project.pbxproj` - Package references
- `class-notes-frontend.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` - Resolved packages
- `buf.gen.yaml` - Proto generation configuration

### Generated Code Location

- All gRPC generated files: `ClassNotes/Core/Networking/gRPC/Generated/`
- Proto files are generated using buf with explicit v2 plugin versions

## 🔄 CI/CD Integration

### GitHub Actions Validation

The validation script is integrated into CI/CD to catch conflicts before they reach main:

```yaml
# Add to .github/workflows/ios.yml
- name: Validate gRPC Packages
  run: |
    cd Frontend
    ./Scripts/validate-packages.sh
```

### Pre-deployment Checks

Before any release:
1. Run full validation on clean environment
2. Test build from scratch
3. Verify all gRPC functionality works
4. Update Package.resolved if needed

## 🚨 Emergency Procedures

### If Main Branch is Broken

1. **Identify the breaking commit**
2. **Revert if necessary** (coordinate with team)
3. **Apply fix using cleanup script**
4. **Validate thoroughly before pushing**

### If Team Member Has Persistent Issues

1. **Help them run cleanup script**
2. **Check their Xcode version** (ensure compatible)
3. **Verify their cache directories** are accessible
4. **Consider pair programming** to resolve

## 📞 Support

### Getting Help

1. **Check this document** first
2. **Run validation script** for specific error messages
3. **Ask in team chat** with:
   - Error message
   - Output of validation script
   - Recent changes made
4. **Create issue** if persistent problem affects entire team

### Updating Guidelines

When you discover new issues or solutions:
1. **Update this document**
2. **Test the solution** thoroughly
3. **Share with team** in next standup
4. **Update scripts** if needed

## 🎯 Success Metrics

### How to Know It's Working

- ✅ No package-related build failures
- ✅ Validation script passes for all team members
- ✅ Pre-commit hooks catch issues before they're committed
- ✅ CI builds pass consistently
- ✅ No more "multiple GUID" errors

### Regular Maintenance

- **Weekly**: Run validation on main branch
- **Monthly**: Review and update this document
- **Per release**: Full package validation on clean environment

---

**Remember**: When in doubt, run the validation script. It's better to catch conflicts early than debug them later!

*Last updated: [Current Date]*
*Document version: 1.0* 