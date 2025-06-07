# Configure OAuth IDs in Your Project

## Step 1: Get Your OAuth Client IDs

First, you need to create OAuth client IDs in Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select your project
3. Go to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**

### Create iOS OAuth Client ID:
- Application type: **iOS**
- Name: "Class Notes iOS"
- Bundle ID: `com.yourcompany.class-notes-frontend` (check your actual bundle ID in Xcode)
- Save and note:
  - **Client ID**: Something like `123456789-abcdefghijklmnop.apps.googleusercontent.com`
  - **Reversed Client ID**: `com.googleusercontent.apps.123456789-abcdefghijklmnop`

### Create Server OAuth Client ID (for backend):
- Application type: **Web application**
- Name: "Class Notes Backend"
- Save and note the **Client ID**

## Step 2: Add Configuration to Your Project

### Method A: Using Xcode Interface (Recommended)

1. Open your project in Xcode
2. Select your project in the navigator
3. Select your app target
4. Go to the **Info** tab
5. Add new entries by hovering over any row and clicking the "+" button:

   **Add Google Client ID:**
   - Key: `GIDClientID`
   - Type: String
   - Value: Your iOS OAuth client ID (e.g., `123456789-abcdefghijklmnop.apps.googleusercontent.com`)

   **Add Server Client ID:**
   - Key: `GIDServerClientID`
   - Type: String
   - Value: Your server OAuth client ID

6. Add URL Scheme:
   - Expand **URL Types** (or add it if not present)
   - Click "+" to add a new URL Type
   - **URL Schemes**: Your reversed client ID (e.g., `com.googleusercontent.apps.123456789-abcdefghijklmnop`)

### Method B: Edit Info.plist Directly

1. In Xcode, right-click on your project → **New File** → **Property List**
2. Name it `Info.plist` (if it doesn't exist)
3. Add this content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entries... -->
    
    <!-- Google Sign-In Configuration -->
    <key>GIDClientID</key>
    <string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>
    
    <key>GIDServerClientID</key>
    <string>YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com</string>
    
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## Step 3: Verify Configuration

1. Build your project (⌘B)
2. The app should launch without the "Google Sign-In configuration not found" error
3. Test Google Sign-In functionality

## Example with Real Values

If your iOS Client ID is: `123456789-abcdefghijklmnop.apps.googleusercontent.com`

Then:
- `GIDClientID`: `123456789-abcdefghijklmnop.apps.googleusercontent.com`
- `CFBundleURLSchemes`: `com.googleusercontent.apps.123456789-abcdefghijklmnop`

## Important Notes

- Never commit real OAuth client IDs to public repositories
- Consider using environment variables or configuration files for different environments
- The reversed client ID must match exactly for OAuth callbacks to work 