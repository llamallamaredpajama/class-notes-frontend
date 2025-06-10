# WhisperKit Integration Guide

WhisperKit has been successfully integrated into your Class Notes project. This guide provides instructions on how to use the speech-to-text functionality.

## Installation Complete ✅

The following components have been added to your project:

1. **WhisperKit Package**: Added to `Package.swift` as a dependency
2. **WhisperKitService**: A service wrapper located at `Core/Services/WhisperKitService.swift`
3. **Example View**: A demo implementation at `Core/Development/WhisperKitExampleView.swift`

## Important Setup Steps

### 1. Microphone Permissions (Required)

You must add the following key to your app's `Info.plist` file to request microphone access:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone to transcribe audio to text.</string>
```

### 2. Update Package Dependencies

In Xcode:
1. Open your project
2. Go to File → Packages → Update to Latest Package Versions
3. Wait for WhisperKit to download (this may take a few minutes)

## Model Distribution Options

### Option 1: On-Demand Download (Default)

By default, WhisperKit downloads models from Hugging Face when first needed:

```swift
// Models are downloaded automatically on first use
await whisperService.initializeWhisperKit(modelName: "base")
```

**Pros:**
- Smaller app size
- Users only download models they need
- Always get the latest model version

**Cons:**
- Requires internet on first use
- Initial delay while downloading

### Option 2: Bundle Models with App

You can pre-bundle WhisperKit models to avoid downloads:

#### Step 1: Download Models

First, download the desired models using the WhisperKit CLI:

```bash
# Clone WhisperKit repository
git clone https://github.com/argmaxinc/whisperkit.git
cd whisperkit

# Setup environment
make setup

# Download specific model (e.g., base)
make download-model MODEL=base

# The model will be in: Models/whisperkit-coreml/openai_whisper-base/
```

#### Step 2: Add Models to Xcode

1. In Xcode, create a new folder group called `WhisperKitModels` in your project
2. Drag the downloaded model folder (e.g., `openai_whisper-base`) into this group
3. **Important**: When adding, ensure:
   - ✅ "Create folder references" is selected (NOT "Create groups")
   - ✅ "Copy items if needed" is checked
   - ✅ Add to your app target

#### Step 3: Update WhisperKitService

Add this method to your `WhisperKitService.swift`:

```swift
/// Initialize WhisperKit with a bundled model from the app bundle
public func initializeWhisperKitWithBundledModel(
    modelName: String = "base", 
    modelFolderName: String = "WhisperKitModels"
) async {
    guard modelState != .loading else { return }
    
    modelState = .loading
    isLoading = true
    selectedModel = modelName
    
    do {
        // Get the path to the bundled model folder
        guard let modelFolderURL = Bundle.main.url(
            forResource: modelFolderName, 
            withExtension: nil
        ) else {
            throw NSError(
                domain: "WhisperKit", 
                code: 404, 
                userInfo: [NSLocalizedDescriptionKey: "Model folder not found"]
            )
        }
        
        // Initialize with bundled model
        let config = WhisperKitConfig(
            model: modelName,
            modelFolder: modelFolderURL.path,
            computeOptions: WhisperKitConfig.ComputeOptions(
                melCompute: .cpuAndGPU,
                audioEncoderCompute: .cpuAndGPU,
                textDecoderCompute: .cpuAndGPU
            ),
            verbose: true,
            logLevel: .debug,
            prewarm: true,
            load: true,
            download: false  // Don't download when using bundled models
        )
        
        whisperKit = try await WhisperKit(config)
        modelState = .loaded(modelName: modelName)
        
    } catch {
        modelState = .failed(error: error.localizedDescription)
    }
    
    isLoading = false
}
```

#### Step 4: Use Bundled Model

```swift
// Initialize with bundled model
await whisperService.initializeWhisperKitWithBundledModel(modelName: "base")
```

### Option 3: Hybrid Approach

You can bundle a small model (like `tiny`) for immediate use, then download larger models as needed:

```swift
// Start with bundled tiny model for immediate availability
await whisperService.initializeWhisperKitWithBundledModel(modelName: "tiny")

// Later, download and switch to a better model
await whisperService.changeModel(to: "base")
```

## Model File Structure

WhisperKit models consist of several files:

## Using WhisperKit in Your App

### Basic Usage

```swift
import SwiftUI

struct MyView: View {
    @StateObject private var whisperService = WhisperKitService()
    
    var body: some View {
        // Your view code
    }
    
    .task {
        // Initialize WhisperKit with a model
        await whisperService.initializeWhisperKit(modelName: "base")
    }
}
```

### Transcribing Audio

```swift
// From a file URL
let transcription = await whisperService.transcribeAudio(from: audioURL)

// From audio samples
let transcription = await whisperService.transcribeAudio(from: audioSamples)

// With timestamps
let segments = await whisperService.transcribeWithTimestamps(from: audioURL)
```

## Available Models

WhisperKit supports the following models (from smallest to largest):

- `tiny` - Fastest, least accurate
- `tiny.en` - English-only tiny model
- `base` - Good balance of speed and accuracy (recommended for testing)
- `base.en` - English-only base model
- `small` - Better accuracy, slower
- `small.en` - English-only small model
- `medium` - High accuracy
- `medium.en` - English-only medium model
- `large-v3` - Best accuracy, slowest
- `distil-large-v3` - Distilled version of large-v3, faster

**Note**: The first time you use a model, WhisperKit will automatically download it. Model sizes range from ~40MB (tiny) to ~3GB (large-v3).

## Features

The WhisperKitService provides:

- ✅ Automatic model downloading and management
- ✅ Progress tracking during transcription
- ✅ Support for various audio formats (WAV, MP3, M4A, FLAC)
- ✅ Timestamp extraction for each transcribed segment
- ✅ Real-time transcription progress updates
- ✅ Multiple language support (with auto-detection)

## Performance Considerations

1. **Model Selection**: Choose models based on your needs:
   - For real-time transcription: Use `tiny` or `base`
   - For accuracy: Use `small` or larger
   - For English-only content: Use `.en` variants for better performance

2. **Device Requirements**:
   - Newer devices (iPhone 12+, M1 Macs) handle larger models well
   - Older devices should stick to smaller models

3. **Memory Usage**: Larger models require more RAM:
   - tiny: ~39MB
   - base: ~74MB
   - small: ~244MB
   - medium: ~769MB
   - large: ~1550MB

## Example Implementation

See `WhisperKitExampleView.swift` for a complete working example that demonstrates:
- Model selection and loading
- Audio recording
- Transcription with progress tracking
- UI best practices

## Troubleshooting

1. **Build Errors**: Make sure to update package dependencies in Xcode
2. **Microphone Access**: Ensure Info.plist has the microphone usage description
3. **Model Download Failed**: Check internet connection and available storage
4. **Poor Transcription Quality**: Try using a larger model

## Additional Resources

- [WhisperKit GitHub Repository](https://github.com/argmaxinc/WhisperKit)
- [WhisperKit Documentation](https://github.com/argmaxinc/WhisperKit#readme)
- [Model Benchmarks](https://huggingface.co/spaces/argmaxinc/whisperkit-benchmarks)

## Support

For WhisperKit-specific issues, please refer to the [WhisperKit GitHub Issues](https://github.com/argmaxinc/WhisperKit/issues) page. 
