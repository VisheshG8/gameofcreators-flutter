# Native Google Authentication Setup Guide

This guide explains how to configure native Google Sign-In for the Flutter mobile app, which bypasses WebView OAuth limitations.

## Overview

The app now uses **native Google Sign-In** instead of WebView OAuth. This approach:
- ✅ Keeps users in the app (no external browser redirects)
- ✅ Preserves session state properly
- ✅ Shows existing Google accounts from device
- ✅ Works seamlessly with Supabase authentication

## Prerequisites

1. **Google Cloud Console Setup**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create or select your project
   - Enable Google+ API
   - Create OAuth 2.0 credentials:
     - **Android Client ID** (for Android app)
     - **iOS Client ID** (for iOS app)
     - **Web Client ID** (for Supabase - this is the one we need!)

2. **Supabase Configuration**
   - Get your Supabase URL and Anon Key from [Supabase Dashboard](https://app.supabase.com)
   - Navigate to: Project Settings → API

## Configuration Steps

### Step 1: Update App Constants

Edit `lib/constants/app_constants.dart` and replace the placeholder values:

```dart
// Supabase Configuration
static const String supabaseUrl = 'https://your-project.supabase.co';
static const String supabaseAnonKey = 'your-anon-key-here';

// Google Sign-In Configuration
// IMPORTANT: Use the Web Client ID (not Android/iOS client ID)
static const String googleWebClientId = 'your-web-client-id.apps.googleusercontent.com';
```

**⚠️ Important**: Use the **Web Client ID** from Google Cloud Console, not the Android or iOS client ID. This is the same client ID configured in Supabase.

### Step 2: Configure Android

1. **Add SHA-1 Fingerprint** (for debug builds):
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy the SHA-1 fingerprint and add it to your Android OAuth client in Google Cloud Console.

2. **Update `android/app/build.gradle.kts`**:
   - Ensure `minSdkVersion` is at least 21
   - Ensure package name matches your Google Cloud Console configuration

### Step 3: Configure iOS

1. **Update `ios/Runner/Info.plist`**:
   - Add your iOS OAuth Client ID to the URL scheme (if needed)
   - Ensure bundle identifier matches your Google Cloud Console configuration

2. **Update `ios/Runner/Info.plist`** with reverse client ID:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

### Step 4: Install Dependencies

Run:
```bash
flutter pub get
```

### Step 5: Test the Implementation

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Test Google Sign-In**:
   - Navigate to the sign-in page in the WebView
   - Click "Continue with Google"
   - The native Google Sign-In dialog should appear
   - Select an account
   - The session should be injected into the WebView automatically

## How It Works

1. **User clicks "Continue with Google"** in the WebView
2. **Flutter intercepts** the Google OAuth URL
3. **Native Google Sign-In** dialog appears (shows device accounts)
4. **User selects account** → Google returns ID token
5. **Flutter exchanges** ID token for Supabase session
6. **Session is injected** into WebView via:
   - JavaScript injection (sets session in Supabase client)
   - Cookie injection (fallback for SSR)
7. **WebView reloads** → User is authenticated

## Troubleshooting

### "No ID Token found"
- Ensure you're using the **Web Client ID** (not Android/iOS client ID)
- Check that Google Sign-In is properly configured in Google Cloud Console

### "Failed to create Supabase session"
- Verify Supabase URL and Anon Key are correct
- Check that the Web Client ID matches the one in Supabase settings
- Ensure Google provider is enabled in Supabase Dashboard

### Session not persisting in WebView
- Check browser console for JavaScript errors
- Verify `mobile-auth-bridge.js` is loaded (check Network tab)
- Ensure cookies are being set (check Application → Cookies)

### Google Sign-In dialog not showing
- Verify SHA-1 fingerprint is added to Google Cloud Console (Android)
- Check bundle identifier matches (iOS)
- Ensure `google_sign_in` package is properly installed

## Files Modified

- ✅ `pubspec.yaml` - Added `google_sign_in` and `supabase_flutter` packages
- ✅ `lib/main.dart` - Initialize Supabase
- ✅ `lib/constants/app_constants.dart` - Added Supabase and Google config
- ✅ `lib/services/auth_service.dart` - Native authentication service
- ✅ `lib/screens/webview_screen.dart` - OAuth interception and session injection
- ✅ `GoViral/public/mobile-auth-bridge.js` - JavaScript bridge for session injection
- ✅ `GoViral/app/layout.tsx` - Added mobile auth bridge script

## Next Steps

1. Replace placeholder values in `app_constants.dart`
2. Configure Google Cloud Console with correct client IDs
3. Test on both Android and iOS devices
4. Deploy the updated website with `mobile-auth-bridge.js`

## Support

If you encounter issues:
1. Check the Flutter console for error messages
2. Check browser console (in WebView) for JavaScript errors
3. Verify all configuration values are correct
4. Ensure Google Cloud Console and Supabase are properly configured

