# How to Find Your Bundle Identifier

Your Bundle ID is needed when creating the OAuth client ID in Google Cloud Console.

## Steps to Find Bundle ID in Xcode:

1. Open your project in Xcode
2. Click on your project name in the navigator (top of file list)
3. Select your app target (under TARGETS)
4. Go to the **General** tab
5. Look for **Bundle Identifier** field

It will look something like:
- `com.yourcompany.class-notes-frontend`
- `com.jeremyhoenig.class-notes-frontend`
- `org.yourorganization.class-notes-frontend`

## Quick Alternative:

1. In Xcode, select your project
2. Go to **Signing & Capabilities** tab
3. The Bundle Identifier is shown there too

**Note**: Make sure this Bundle ID matches exactly when creating your iOS OAuth client ID in Google Cloud Console! 