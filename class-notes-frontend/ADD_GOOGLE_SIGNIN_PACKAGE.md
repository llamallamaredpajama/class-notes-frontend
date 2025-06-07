# How to Add Google Sign-In SDK to Your Xcode Project

## Step-by-Step Instructions:

### 1. Open Your Project in Xcode
- Open `class-notes-frontend.xcodeproj` in Xcode

### 2. Add Package Dependency
1. In Xcode, go to **File** → **Add Package Dependencies...**
   (Or click on your project in the navigator, then the project name under "PROJECT", then "Package Dependencies" tab)

2. In the search field, enter:
   ```
   https://github.com/google/GoogleSignIn-iOS
   ```

3. Wait for the package to load, then:
   - **Dependency Rule**: Choose "Up to Next Major Version"
   - **Version**: Set to **7.1.0** (or latest)
   - Click **Add Package**

4. When prompted to choose package products, select:
   - ✅ **GoogleSignIn** (add to "class-notes-frontend" target)
   - ✅ **GoogleSignInSwift** (add to "class-notes-frontend" target)
   - Click **Add Package**

### 3. Clean and Build
1. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
2. Build project: **Product** → **Build** (⌘B)

## Alternative Method (if the above doesn't work):

### Remove and Re-add Package:
1. Go to your project settings
2. Click on "Package Dependencies" tab
3. If GoogleSignIn is there but not working, remove it (select and press -)
4. Add it again following the steps above

### Check Target Membership:
1. Select `GoogleSignInService.swift` in the navigator
2. In the File Inspector (right panel), ensure "Target Membership" has your app target checked

## If Still Having Issues:

1. **Quit Xcode completely** (⌘Q)
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/
   ```
3. Reopen Xcode and try building again

## Verify Package is Added:
You should see "Package Dependencies" in your project navigator with:
- GoogleSignIn-iOS package listed

The import statements should now work without errors! 