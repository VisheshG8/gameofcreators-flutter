# OneSignal Push Notifications - Quick Guide

## 🚨 CRITICAL: How to Send Notifications

### ✅ THE RIGHT WAY (Opens in App):

**In OneSignal Dashboard:**
1. Messages → New Push
2. Title: "New Message"
3. Body: "Check this out"
4. **⚠️ LEAVE "LAUNCH URL" FIELD BLANK**
5. Advanced Settings → Additional Data:
   - Key: `target_url`
   - Value: `https://www.gameofcreators.com/dashboard/messages`
6. Set Priority to HIGH
7. Send!

**Result:** ✅ App opens → Webview navigates to URL

---

### ❌ THE WRONG WAY (Opens in Chrome):

**In OneSignal Dashboard:**
1. Launch URL: `https://www.gameofcreators.com/...`

**Result:** ❌ Chrome browser opens (NOT your app)

---

## 📱 App Links Setup (Optional Bonus)

For WhatsApp/SMS links to open in your app, create this file on your server:

**File:** `https://www.gameofcreators.com/.well-known/assetlinks.json`

**Content:**
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

**Test:**
```bash
curl https://www.gameofcreators.com/.well-known/assetlinks.json
```

See [ASSETLINKS_SETUP.md](ASSETLINKS_SETUP.md) for detailed instructions.

---

## 🧪 Testing

1. Get device ID from app logs
2. Send test notification with `target_url` in Additional Data
3. Click notification
4. **Expected:** App opens, webview navigates to URL
5. **Console shows:** `✅ Found target_url in Additional Data: [url]`

---

## 🎯 Summary

| Method | Android Behavior | Result |
|--------|------------------|--------|
| **Launch URL field** | Opens Chrome | ❌ Wrong |
| **target_url in Additional Data** | Opens App | ✅ Correct |
| **assetlinks.json** | Bonus for WhatsApp/SMS | ✅ Optional |

**Always use Additional Data for notifications!**
