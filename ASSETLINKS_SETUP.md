# Android App Links Setup (assetlinks.json)

## ⚠️ CRITICAL: Without this file, Android may open Chrome instead of your app!

This file tells Android that your app is authorized to open links from `gameofcreators.com`.

## What You Need To Do:

### 1. Create the assetlinks.json file on your server

**File Location:** `https://www.gameofcreators.com/.well-known/assetlinks.json`

**File Content:**

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.gameofcreators.mobile",
      "sha256_cert_fingerprints": [
        "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B"
      ]
    }
  }
]
```

### 2. Server Configuration

**Important Requirements:**

- File MUST be accessible via HTTPS (not HTTP)
- Content-Type header MUST be `application/json`
- File MUST be publicly accessible (no authentication required)
- No redirects allowed

**Test the file:**

```bash
curl -I https://www.gameofcreators.com/.well-known/assetlinks.json
```

Should return:

```
HTTP/2 200
content-type: application/json
```

### 3. Verify the Setup

**Option A: Use Google's Testing Tool**

1. Go to: https://developers.google.com/digital-asset-links/tools/generator
2. Enter your domain: `gameofcreators.com`
3. Select "Android App"
4. Enter package name: `com.gameofcreators.mobile`
5. Enter fingerprint: `E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B`
6. Click "Test statement"

**Option B: Manual Test**

```bash
curl https://www.gameofcreators.com/.well-known/assetlinks.json
```

### 4. Clear Android App Links Settings (if needed)

If links were opening in Chrome before:

1. Go to **Settings → Apps → Game of Creators**
2. Tap **"Open by default"** or **"Set as default"**
3. Tap **"Open supported links"**
4. Select **"Open in this app"**

Or clear the domain verification:

```bash
adb shell pm set-app-links --package com.gameofcreators.mobile 0 all
adb shell pm verify-app-links --re-verify com.gameofcreators.mobile
```

## What This Fixes:

### Before assetlinks.json:

❌ Notification with URL → Opens Chrome
❌ WhatsApp link → Opens Chrome
❌ SMS link → Opens Chrome

### After assetlinks.json:

✅ Notification with URL → Opens your app (when using Additional Data)
✅ WhatsApp link → Opens your app
✅ SMS link → Opens your app

## Important Notes:

### For Notifications (OneSignal):

- **Still use `target_url` in Additional Data** (safest)
- assetlinks.json is a BONUS for deep links from WhatsApp/SMS
- Do NOT rely on Launch URL field with assetlinks.json

### For Multiple Domains:

If you also use `gameofcreators.com` (without www):

- Create assetlinks.json at both:
  - `https://www.gameofcreators.com/.well-known/assetlinks.json`
  - `https://gameofcreators.com/.well-known/assetlinks.json`

### For Production/Release Builds:

When you create a release build with a different signing key:

1. Get the new SHA-256 fingerprint:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. Add the new fingerprint to assetlinks.json:
   ```json
   "sha256_cert_fingerprints": [
     "E2:F3:E3:A7:74:D5:86:82:B2:01:58:3B:F3:3E:24:C6:28:D4:24:90:EF:8D:9C:D3:DC:6F:88:C8:7C:8C:14:2B",
     "YOUR_RELEASE_FINGERPRINT_HERE"
   ]
   ```

## Troubleshooting:

### Links still opening in Chrome?

1. ✅ Check file is accessible: `curl https://www.gameofcreators.com/.well-known/assetlinks.json`
2. ✅ Check Content-Type header is `application/json`
3. ✅ Check package name matches: `com.gameofcreators.mobile`
4. ✅ Check SHA-256 fingerprint is correct
5. ✅ Clear app data and reinstall
6. ✅ Wait 24 hours (Android caches verification results)

### How to force re-verification?

```bash
adb shell pm verify-app-links --re-verify com.gameofcreators.mobile
adb shell pm get-app-links com.gameofcreators.mobile
```

## Additional Resources:

- [Android App Links Official Docs](https://developer.android.com/training/app-links)
- [Digital Asset Links Tool](https://developers.google.com/digital-asset-links/tools/generator)
- [OneSignal Deep Linking Guide](https://documentation.onesignal.com/docs/links)

---

**Remember:** For notifications, ALWAYS use `target_url` in Additional Data!
assetlinks.json is a bonus for WhatsApp/SMS links.
