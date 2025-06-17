# gRPC Setup for ClassNotes iOS

This directory contains the gRPC client implementation for the ClassNotes iOS app.

## Structure

```
gRPC/
├── Generated/          # Generated Swift files from proto definitions
├── Interceptors/       # Custom interceptors for auth, logging, and retry
└── README.md          # This file
```

## Setup Instructions

### 1. Install Dependencies

First, install the required tools:

```bash
# Install protobuf compiler
brew install protobuf

# Install Swift protobuf plugin
brew install swift-protobuf

# Install gRPC Swift plugin
brew install grpc-swift
```

### 2. Add Swift Package Dependencies

In Xcode, add the following dependencies via Swift Package Manager:

1. **grpc-swift**: `https://github.com/grpc/grpc-swift.git` (version 1.21.0 or later)
2. **swift-protobuf**: `https://github.com/apple/swift-protobuf.git` (version 1.25.0 or later)

### 3. Generate Proto Files

Run the generation script:

```bash
cd Frontend/class-notes-frontend
./Scripts/generate-protos.sh
```

This will generate Swift files from the proto definitions in the Backend directory.

### 4. Add Generated Files to Xcode

1. In Xcode, right-click on the `Generated` folder
2. Select "Add Files to ClassNotes..."
3. Select all the generated `.swift` files
4. Make sure "Copy items if needed" is unchecked
5. Add to target: ClassNotes

## Interceptors

The gRPC client uses three interceptors:

### AuthInterceptor
- Adds authentication token to all requests
- Handles authentication failures
- Manages token refresh

### LoggingInterceptor
- Logs all gRPC requests and responses
- Configurable log levels
- Performance tracking

### RetryInterceptor
- Automatic retry with exponential backoff
- Configurable retry policies
- Handles transient network failures

## Usage Example

```swift
// Get the gRPC client
let client = try GRPCClientManager.shared.getClassNotesClient()

// Upload a transcript
let request = Classnotes_V1_UploadTranscriptRequest.with {
    $0.classNoteID = "note123"
    $0.transcript = Classnotes_V1_TranscriptRequest.with {
        $0.audioData = audioData
        $0.mimeType = "audio/m4a"
        $0.durationSeconds = 120.0
        $0.language = "en-US"
    }
    $0.options = Classnotes_V1_ProcessingOptions.with {
        $0.quality = .high
        $0.includeTranscript = true
        $0.includeSummary = true
    }
}

do {
    let response = try await client.uploadTranscript(request)
    print("Upload successful: \(response.classNoteID)")
} catch {
    print("Upload failed: \(error)")
}
```

## Troubleshooting

### Module 'GRPC' not found
- Make sure you've added the grpc-swift package dependency in Xcode
- Clean build folder (Cmd+Shift+K) and rebuild

### Proto generation fails
- Ensure protoc and plugins are installed correctly
- Check that Backend proto files exist
- Verify paths in generate-protos.sh script

### Authentication errors
- Check that auth token is stored in Keychain
- Verify token hasn't expired
- Check server logs for auth issues 