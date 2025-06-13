# Simulator Testing Guide for Class Notes App

## Overview

The Class Notes app now supports conditional authentication based on the build target:
- **Simulator**: Uses mock authentication service for fast UI development
- **Physical Device**: Uses real Google Sign-In for end-to-end testing

## How It Works

The app automatically detects whether it's running on a simulator or physical device:

```swift
#if targetEnvironment(simulator)
    // Mock authentication service
#else
    // Real authentication service
#endif
```

## Benefits

### 🚀 Fast UI Development (Simulator)
- **Target**: iPad/iPhone Simulator
- **Features**:
  - Instant sign-in (no Google OAuth flow)
  - Mock user data pre-populated
  - Simulated network delays for realistic UX
  - Console logging for debugging
  - No need for GoogleService-Info.plist during development

### ✅ Full Testing (Physical Device)
- **Target**: Your physical iPad/iPhone
- **Features**:
  - Real Google Sign-In flow
  - Actual backend integration
  - Complete user journey testing
  - Production-like experience

## Usage

### Running on Simulator

1. Select a simulator as your build target in Xcode
2. Build and run the app
3. Tap "Sign in with Google"
4. You'll be instantly signed in with a test user

**Console Output:**
```
📱 Running on Simulator - Using Mock Authentication Service
🔵 Mock Authentication: Simulating Google Sign-In...
✅ Mock Authentication: User signed in successfully
```

### Running on Physical Device

1. Connect your iPad/iPhone via USB
2. Select your device as the build target
3. Build and run the app
4. Tap "Sign in with Google"
5. Complete the real Google OAuth flow

**Console Output:**
```
📱 Running on Physical Device - Using Real Authentication Service
```

## Mock User Details

When running on simulator, the mock user has:
- **Email**: test.user@classnotes.dev
- **Name**: Test User
- **Profile Image**: Generated avatar
- **Preferences**: Default settings

## Tips

1. **Switching Between Modes**: Simply change your build target in Xcode's device selector
2. **Testing Auth States**: The mock service includes realistic delays to simulate network requests
3. **Debugging**: Check console logs for authentication flow details
4. **Preview Support**: SwiftUI previews also use the mock authentication service

## Next Steps

Before deploying to production:
1. Add GoogleService-Info.plist to the project
2. Uncomment Google Sign-In configuration in ClassNotesApp.swift
3. Test thoroughly on physical devices
4. Ensure all authentication flows work correctly 