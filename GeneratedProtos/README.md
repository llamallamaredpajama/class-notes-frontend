# Generated Proto Files

This directory contains the generated protobuf and gRPC code for ClassNotes.

## Generated Files

- `classnotes_service.pb.swift` - Protocol buffer message definitions
- `classnotes_service.grpc.swift` - gRPC client code

## Usage in Xcode

### As a Local Swift Package (Recommended)

1. In Xcode, go to File → Add Package Dependencies
2. Click "Add Local..."
3. Navigate to and select the GeneratedProtos folder
4. Click "Add Package"
5. Import in your code: `import GeneratedProtos`

### Direct File Import (Not Recommended)

1. Drag the Sources folder into your Xcode project
2. Make sure "Copy items if needed" is UNCHECKED
3. Add to your target

## Important Notes

- These files are generated OUTSIDE of Xcode to avoid build-time conflicts
- Do NOT add proto generation as a build phase in Xcode
- To regenerate, run: `./Scripts/generate-protos-direct.sh`
- The generated code uses gRPC-Swift v2 APIs correctly
