# Google Sign-In Setup Guide for Class Notes

## Prerequisites
- Xcode (latest version)
- Google Cloud Console account
- Apple Developer account (for signing the app)

## Step 1: Add Google Sign-In SDK via Swift Package Manager

1. Open your project in Xcode (`class-notes-frontend.xcodeproj`)
2. Go to **File → Add Package Dependencies**
3. Enter this repository URL: `https://github.com/google/GoogleSignIn-iOS`
4. Set version to **7.1.0** or later (required for Apple's Privacy Manifest)
5. Add these packages:
   - **GoogleSignIn**
   - **GoogleSignInSwift** (for SwiftUI support)

## Step 2: Create OAuth Client IDs

### Create iOS OAuth Client ID:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google Sign-In API
4. Go to **Credentials** → **Create Credentials** → **OAuth client ID**
5. Select **iOS** as application type
6. Enter:
   - Name: "Class Notes iOS"
   - Bundle ID: Your app's bundle identifier (check in Xcode)
7. Save and note down:
   - **Client ID**: `YOUR_IOS_CLIENT_ID`
   - **Reversed Client ID**: `com.googleusercontent.apps.YOUR_ID`

### Create Server OAuth Client ID (for backend):
1. Create another OAuth client ID
2. Select **Web application** as type
3. Name: "Class Notes Backend"
4. Save and note down the **Server Client ID**

## Step 3: Configure Info.plist

Add these keys to your `Info.plist`:

```xml
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
<key>GIDServerClientID</key>
<string>YOUR_SERVER_CLIENT_ID</string>
```

## Step 4: Update Code Implementation

The code implementation has been updated in:
- `GoogleSignInService.swift` - Handles Google Sign-In logic
- `ClassNotesSignInView.swift` - Updated to use real Google Sign-In
- `class_notes_frontendApp.swift` - Configured to handle URL callbacks

## Step 5: Download Official Google Logo

1. Visit [Google Brand Guidelines](https://developers.google.com/identity/branding-guidelines)
2. Download the official "G" logo for light backgrounds
3. Replace the placeholder images in `Assets.xcassets/google-logo.imageset/`

## Step 6: Test Sign-In

1. Build and run the app
2. Click "Sign in with Google"
3. Complete the OAuth flow
4. Verify successful authentication

## Important Notes

- Ensure your app is signed with a valid certificate
- For production, implement proper token validation
- Store sensitive tokens in Keychain
- Follow Google's branding guidelines for the sign-in button 