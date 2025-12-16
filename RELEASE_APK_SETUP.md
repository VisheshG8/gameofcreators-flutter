# Release APK Deep Linking Setup Guide

## Current Status

Your app is currently configured to use the **debug keystore** for release builds:

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        // Signing with the debug keys for now
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

**SHA-256 Fingerprint (Debug/Current):**
```
E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B
```

## ⚠️ IMPORTANT: For Production Release

### If Continuing with Debug Keystore (NOT RECOMMENDED)

**Will deep linking work?** ✅ **YES** - because your server's `assetlinks.json` already has this debug fingerprint.

**However, this is NOT recommended because:**
- Debug keystores are not secure
- Google Play Console won't accept it for some features
- You can't sign updates consistently

### For Production Release (RECOMMENDED)

You need to create a **production release keystore** and update your configuration.

## Step-by-Step: Production Release Setup

### Step 1: Create Release Keystore

```bash
# Navigate to android/app directory
cd android/app

# Create a release keystore (SAVE THIS FILE SECURELY!)
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias game-of-creators-release

# You'll be prompted for:
# - Keystore password (REMEMBER THIS!)
# - Key password (REMEMBER THIS!)
# - Your name/organization details
```

**CRITICAL:** Save these securely:
- `release-keystore.jks` file
- Keystore password
- Key alias: `game-of-creators-release`
- Key password

### Step 2: Get Release SHA-256 Fingerprint

```bash
# Get the SHA-256 fingerprint of your new release key
keytool -list -v -keystore android/app/release-keystore.jks \
  -alias game-of-creators-release

# Look for the SHA-256 line, it will look like:
# SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX...
```

Copy this SHA-256 fingerprint - you'll need it for the next step.

### Step 3: Update Server's assetlinks.json

Update your file at `https://www.gameofcreators.com/.well-known/assetlinks.json` to include **BOTH** debug and release fingerprints:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.gameofcreators.mobile",
    "sha256_cert_fingerprints": [
      "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B",
      "YOUR_RELEASE_SHA256_FINGERPRINT_HERE"
    ]
  }
}]
```

**Why include both?**
- Debug fingerprint: For testing during development
- Release fingerprint: For production app from Play Store

### Step 4: Configure Gradle for Release Signing

Create `android/key.properties` (add to .gitignore!):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=game-of-creators-release
storeFile=release-keystore.jks
```

**IMPORTANT:** Add to `.gitignore`:
```
# Release keystore
android/app/release-keystore.jks
android/key.properties
```

### Step 5: Update build.gradle.kts

Replace your current release configuration:

```kotlin
// At the top of the file, after plugins block
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### Step 6: Build and Test Release APK

```bash
# Build release APK
flutter build apk --release

# Install and test
adb install build/app/outputs/flutter-apk/app-release.apk

# Verify signing
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk | grep SHA256

# Should match your release fingerprint!
```

### Step 7: Test Deep Linking with Release APK

```bash
# After installing release APK, approve app links
adb shell pm set-app-links --package com.gameofcreators.mobile 2 www.gameofcreators.com
adb shell pm set-app-links --package com.gameofcreators.mobile 2 gameofcreators.com

# Test deep link
adb shell am start -a android.intent.action.VIEW -d "https://www.gameofcreators.com/auth/signin"

# Check logs
adb logcat | grep "MainActivity.*Deep link"
```

## Play Store Upload Considerations

### Using Play App Signing (Recommended)

When you upload to Play Store with Play App Signing enabled:

1. **Google creates an upload key** for you
2. **Google generates a separate signing key** for distribution
3. **You need THREE fingerprints** in assetlinks.json:
   - Your debug key (for development)
   - Your upload key (for uploading to Play Store)
   - Google's app signing key (for users downloading from Play Store)

**How to get Google's signing key:**
1. Upload your first release to Play Console
2. Go to: Release → Setup → App integrity
3. Copy the "SHA-256 certificate fingerprint" under "App signing"
4. Add it to your assetlinks.json

**Final assetlinks.json for Play Store:**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.gameofcreators.mobile",
    "sha256_cert_fingerprints": [
      "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B",
      "YOUR_UPLOAD_KEY_SHA256",
      "GOOGLE_APP_SIGNING_KEY_SHA256"
    ]
  }
}]
```

## Quick Answer to Your Question

### Will deep linking work for release APK?

**If using debug keystore (current setup):** ✅ **YES**
- Your assetlinks.json already has the debug fingerprint
- But NOT recommended for production

**If using proper release keystore:** ⚠️ **ONLY AFTER** you:
1. Create release keystore
2. Get its SHA-256 fingerprint
3. Add it to assetlinks.json on your server
4. Wait a few minutes for Android to re-verify

**If uploading to Play Store with App Signing:** ⚠️ **ONLY AFTER** you:
1. Upload to Play Store
2. Get Google's signing key SHA-256 from Play Console
3. Add it to assetlinks.json
4. Users must download from Play Store (not sideloaded APK)

## Testing Checklist

Before releasing:

- [ ] Created production keystore
- [ ] Got SHA-256 fingerprint
- [ ] Updated assetlinks.json with release fingerprint
- [ ] Verified assetlinks.json is accessible: `curl https://www.gameofcreators.com/.well-known/assetlinks.json`
- [ ] Built release APK: `flutter build apk --release`
- [ ] Verified APK signature matches: `keytool -printcert -jarfile app-release.apk | grep SHA256`
- [ ] Installed release APK on test device
- [ ] Set app links: `adb shell pm set-app-links --package com.gameofcreators.mobile 2 www.gameofcreators.com`
- [ ] Tested deep link: `adb shell am start -a android.intent.action.VIEW -d "https://www.gameofcreators.com/..."`
- [ ] Tested WhatsApp link opens in app
- [ ] If uploading to Play Store: Added Google's signing key to assetlinks.json

## Common Issues

### Issue: Release APK deep links don't work

**Solution:** Check that assetlinks.json has the correct release fingerprint:

```bash
# Get fingerprint from installed APK
adb shell pm dump com.gameofcreators.mobile | grep "signatures"

# Compare with assetlinks.json
curl https://www.gameofcreators.com/.well-known/assetlinks.json | grep sha256
```

### Issue: Play Store version doesn't work but sideloaded APK does

**Solution:** Add Google's App Signing key to assetlinks.json (see Play Store Upload section above)

### Issue: Android says "App not verified"

**Solution:**
1. Verify assetlinks.json is accessible and has correct format
2. Wait 10-15 minutes for Android to re-verify
3. Force re-verification: `adb shell pm verify-app-links --re-verify com.gameofcreators.mobile`

## Summary

**Current Setup (Debug Keystore):**
- ✅ Deep linking works NOW
- ❌ NOT suitable for production/Play Store

**Recommended Setup (Release Keystore):**
- ✅ Secure and professional
- ✅ Works with Play Store
- ⚠️ Requires updating assetlinks.json with new fingerprint

**Play Store with App Signing:**
- ✅ Most secure (Google manages keys)
- ✅ Best practice
- ⚠️ Requires THREE fingerprints in assetlinks.json

---

**Next Steps:**
1. Decide: Continue with debug keystore (quick) OR create release keystore (recommended)
2. If release keystore: Follow Steps 1-7 above
3. If Play Store: Also follow "Play Store Upload Considerations"

**Status:** Ready for implementation
**Last Updated:** 2025-12-16
