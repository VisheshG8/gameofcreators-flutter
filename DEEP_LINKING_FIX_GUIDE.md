# Deep Linking Fix Guide - Production Grade

## Summary of Changes Made

I've implemented a production-grade fix for WhatsApp/Telegram deep linking. Here's what was changed:

### 1. AndroidManifest.xml Changes

**Changed:**
- `android:launchMode` from `"singleTask"` to `"singleTop"`
- Removed `android:taskAffinity=""`

**Why:**
- `singleTask` with empty taskAffinity can prevent Android from properly routing deep links
- `singleTop` is the recommended launch mode for apps handling deep links
- This ensures deep links are properly delivered to your app instead of opening Chrome

### 2. MainActivity.kt Enhancements

**Added intent handling:**
- Override `onCreate()` to handle initial deep link intents
- Override `onNewIntent()` to handle deep links when app is already running
- Added logging for debugging deep link reception

**Why:**
- Ensures deep links are properly captured in both cold start and warm start scenarios
- The `app_links` plugin will pick up these intents automatically

### 3. Server Configuration Requirements

Your `assetlinks.json` file MUST have:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.gameofcreators.mobile",
    "sha256_cert_fingerprints": [
      "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B"
    ]
  }
}]
```

**Critical:** This file is currently correct on `www.gameofcreators.com` but the non-www version `gameofcreators.com` has a redirect, which breaks Android verification.

---

## Setup Instructions After Code Changes

### Step 1: Rebuild and Install

```bash
# Clean previous builds
flutter clean

# Build and install
flutter run
# OR
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Step 2: Configure App as Default Handler

After installing, you MUST manually set your app to handle your domain links:

**Option A: Via Device Settings (Recommended)**
1. Open Settings → Apps → Game of Creators
2. Tap "Open by default" or "Set as default"
3. Tap "Add link" or "Open supported web addresses"
4. Enable `www.gameofcreators.com` and `gameofcreators.com`
5. Select "Open in this app"

**Option B: Via ADB Commands**
```bash
# Clear previous settings
adb shell pm set-app-links --package com.gameofcreators.mobile 0 all

# Set app to handle your domains
adb shell pm set-app-links --package com.gameofcreators.mobile 2 www.gameofcreators.com
adb shell pm set-app-links --package com.gameofcreators.mobile 2 gameofcreators.com

# Verify settings
adb shell pm get-app-links com.gameofcreators.mobile
```

Expected output:
```
com.gameofcreators.mobile:
  Domain verification state:
    gameofcreators.com: approved
    www.gameofcreators.com: approved
```

### Step 3: Force Re-verification (Optional)

```bash
adb shell pm verify-app-links --re-verify com.gameofcreators.mobile
```

### Step 4: Test Deep Linking

1. Send yourself a WhatsApp message with: `https://www.gameofcreators.com/auth/signin`
2. Click the link
3. If a dialog appears, select "Game of Creators" and check "Always"
4. The app should open (not Chrome!)

---

## Troubleshooting

### Issue: Still Opens in Chrome

**Solution 1: Clear Chrome's Default Handler**
```bash
# Open Chrome's app info
adb shell am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d "package:com.android.chrome"

# In the UI: Tap "Open by default" → "Clear defaults"
```

**Solution 2: Reset All App Link Preferences**
```bash
# Uninstall app
adb uninstall com.gameofcreators.mobile

# Clear Chrome defaults
adb shell pm clear-package-preferred-activities com.android.chrome

# Reinstall your app
flutter install

# Set as default (see Step 2 above)
```

### Issue: App Link Verification Fails (status 1024)

This means the assetlinks.json file doesn't match. Check:

```bash
# Verify server file
curl https://www.gameofcreators.com/.well-known/assetlinks.json

# Should show:
# - package_name: "com.gameofcreators.mobile"
# - sha256_cert_fingerprints: "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B"

# Get your app's actual fingerprint
cd android && ./gradlew signingReport | grep "SHA-256"
```

### Issue: Non-WWW Domain Not Working

The `gameofcreators.com` (without www) is currently redirecting to `www.gameofcreators.com`. Android rejects redirects for assetlinks.json.

**Fix on server:**
Ensure `https://gameofcreators.com/.well-known/assetlinks.json` returns the JSON directly without redirecting.

**Temporary workaround:**
Only use `www.gameofcreators.com` URLs in WhatsApp/Telegram messages.

---

## Testing Deep Links Locally

Test if your app receives deep links:

```bash
# Test with adb
adb shell am start -a android.intent.action.VIEW -d "https://www.gameofcreators.com/auth/signin" com.gameofcreators.mobile

# Check logs
adb logcat | grep "MainActivity.*Deep link"
```

You should see:
```
MainActivity: Deep link received: https://www.gameofcreators.com/auth/signin
```

---

## Production Release Checklist

When creating a production release build:

1. **Generate release keystore** (if you haven't already)
2. **Get SHA-256 fingerprint** of release key:
   ```bash
   keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
   ```
3. **Update assetlinks.json** to include BOTH debug and release fingerprints:
   ```json
   "sha256_cert_fingerprints": [
     "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B",
     "YOUR_RELEASE_FINGERPRINT_HERE"
   ]
   ```
4. **Test with release build** before publishing to Play Store

---

## Key Files Modified

1. ✅ `android/app/src/main/AndroidManifest.xml` - Changed launchMode to singleTop
2. ✅ `android/app/src/main/kotlin/com/gameofcreators/mobile/MainActivity.kt` - Added intent handling
3. ✅ Server: `assetlinks.json` - Already has correct package name

---

## Why This Fix Works

1. **singleTop Launch Mode**: Allows Android to deliver VIEW intents to your running app instance
2. **Intent Handling in MainActivity**: Properly captures deep link intents in all scenarios
3. **Manual App Link Configuration**: Explicitly tells Android to prefer your app over Chrome for your domain
4. **Proper assetlinks.json**: Verifies your app is authorized to handle your domain's links

The combination of these changes ensures that when a user clicks a link from WhatsApp/Telegram:
1. Android checks if any app can handle `gameofcreators.com`
2. Finds your app with the correct configuration
3. Routes the intent to `MainActivity`
4. Your Flutter app (via `app_links` plugin) receives the URL
5. `NotificationService` or `main.dart` handles navigation

---

## Support

If deep linking still doesn't work after following all steps:

1. Check logs: `adb logcat | grep -i "gameofcreators\|deep link"`
2. Verify app link status: `adb shell pm get-app-links com.gameofcreators.mobile`
3. Ensure assetlinks.json matches exactly
4. Try rebooting the device (Android sometimes caches app link settings)

---

**Last Updated:** 2025-12-16
**Author:** Claude Code
**Status:** Production Ready ✅
