# Mobile OAuth Deep Linking - Quick Reference

## 🎯 Quick Overview

This is a condensed reference for implementing OAuth deep linking in the Game of Creators Flutter mobile app.

For complete details, see: [MOBILE_APP_OAUTH_DEEP_LINKING.md](./MOBILE_APP_OAUTH_DEEP_LINKING.md)

---

## 📱 Deep Link Schemes

| Flow | Deep Link URL | Final Redirect |
|------|--------------|----------------|
| **Google Sign-In** | `gameofcreators://auth/callback` | `/dashboard` or `/choose-username` |
| **Instagram Connect** | `gameofcreators://instagram/callback` | `/dashboard/settings` |
| **YouTube Connect** | `gameofcreators://youtube/callback` | `/dashboard/settings` |

---

## 🔧 Backend Changes Required

### 1. Platform Detection

```typescript
// lib/platform-utils.ts
export function detectPlatform(userAgent: string): 'web' | 'ios' | 'android' {
  const ua = userAgent.toLowerCase();
  if (ua.includes('gameofcreators-mobile')) {
    if (ua.includes('android')) return 'android';
    if (ua.includes('ios')) return 'ios';
  }
  return 'web';
}
```

### 2. Google OAuth (SignInPage.tsx, SignUpPage.tsx)

```typescript
const isMobile = /gameofcreators-mobile/i.test(navigator.userAgent);
const redirectTo = isMobile 
  ? 'gameofcreators://auth/callback'
  : `${window.location.origin}/auth/callback`;
```

### 3. Instagram Connection (settings/client.tsx)

```typescript
const isMobile = /gameofcreators-mobile/i.test(navigator.userAgent);
const redirectUri = isMobile
  ? 'gameofcreators://instagram/callback'
  : `${window.location.origin}/api/instagram/callback`;
```

### 4. YouTube Connection (settings/client.tsx)

```typescript
const response = await fetch("/api/youtube/auth", {
  method: "POST",
  body: JSON.stringify({
    platform: isMobile ? 'mobile' : 'web'
  })
});
```

### 5. Update Callback Routes

Add to each callback (`auth/callback`, `instagram/callback`, `youtube/callback`):

```typescript
const userAgent = request.headers.get("user-agent") || "";
const isMobile = /gameofcreators-mobile/i.test(userAgent);

if (isMobile) {
  return NextResponse.redirect(`gameofcreators://[flow]/success?user_id=${user.id}`);
}
```

---

## 📱 Flutter Implementation

### 1. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter_inappwebview: ^6.0.0
  uni_links: ^0.5.1
  url_launcher: ^6.2.0
```

### 2. Android Configuration

**AndroidManifest.xml**:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="gameofcreators" />
  <data android:host="auth" />
  <data android:host="instagram" />
  <data android:host="youtube" />
</intent-filter>
```

### 3. iOS Configuration

**Info.plist**:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>gameofcreators</string>
    </array>
  </dict>
</array>
```

### 4. WebView Setup

```dart
InAppWebView(
  initialOptions: InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      userAgent: 'GameOfCreators-Mobile/${Platform.isAndroid ? "Android" : "iOS"}',
    ),
  ),
  shouldOverrideUrlLoading: (controller, navigationAction) async {
    final uri = navigationAction.request.url!;
    
    // Open OAuth URLs in external browser
    if (_isOAuthUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    
    return NavigationActionPolicy.ALLOW;
  },
)
```

### 5. Deep Link Handler

```dart
class DeepLinkService {
  void initialize() {
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        if (uri.host == 'auth') onAuthCallback?.call(uri);
        if (uri.host == 'instagram') onInstagramCallback?.call(uri);
        if (uri.host == 'youtube') onYouTubeCallback?.call(uri);
      }
    });
  }
}
```

---

## 🔐 OAuth Provider Configuration

### Google Cloud Console

**Add Redirect URIs**:
```
https://gameofcreators.com/auth/callback
https://gameofcreators.com/api/youtube/callback
gameofcreators://auth/callback
gameofcreators://youtube/callback
```

### Instagram App (Meta for Developers)

**Add Valid OAuth Redirect URIs**:
```
https://gameofcreators.com/api/instagram/callback
gameofcreators://instagram/callback
```

### Supabase Dashboard

**Add Redirect URLs**:
```
https://gameofcreators.com/auth/callback
gameofcreators://auth/callback
gameofcreators://auth/success
```

---

## 🧪 Quick Test Commands

### Test Deep Link (Android)

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "gameofcreators://auth/callback?code=test123"
```

### Test Deep Link (iOS)

```bash
xcrun simctl openurl booted "gameofcreators://auth/callback?code=test123"
```

### Test Platform Detection

```bash
# In browser console on mobile WebView
console.log(navigator.userAgent);
// Should contain: GameOfCreators-Mobile/Android or GameOfCreators-Mobile/iOS
```

---

## 🐛 Common Issues & Quick Fixes

### Issue: Deep link not opening app

**Fix**:
```bash
# Verify scheme registration
adb shell dumpsys package d | grep gameofcreators  # Android
```

### Issue: Platform detection failing

**Fix**: Check user agent is set correctly in WebView:
```dart
userAgent: 'GameOfCreators-Mobile/1.0.0 (Android)'
```

### Issue: OAuth loop

**Fix**: Clear cookies and app data:
```bash
adb shell pm clear com.gameofcreators.app  # Android
```

### Issue: Instagram token expires quickly

**Fix**: Ensure long-lived token exchange:
```typescript
// Should exchange for 60-day token
const longLivedTokenRes = await fetch(
  `https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret=${secret}&access_token=${token}`
);
```

---

## 📋 Pre-Deployment Checklist

### Backend
- [ ] Platform detection implemented
- [ ] Mobile redirect URIs added to code
- [ ] Callback routes updated
- [ ] Environment variables set
- [ ] Tested on staging

### Mobile App
- [ ] Deep link scheme configured (Android + iOS)
- [ ] User agent set in WebView
- [ ] Deep link handler implemented
- [ ] OAuth URLs open in external browser
- [ ] Tested on both platforms

### OAuth Providers
- [ ] Google Cloud: Mobile URIs added
- [ ] Instagram App: Mobile URIs added
- [ ] Supabase: Mobile URIs added
- [ ] All changes saved and verified

### Testing
- [ ] Google Sign-In works on mobile
- [ ] Instagram connection works on mobile
- [ ] YouTube connection works on mobile
- [ ] Web flows still work (no regression)
- [ ] Error handling works
- [ ] Token refresh works

---

## 🚀 Deployment Order

1. **Update OAuth Providers** (Google, Instagram, Supabase)
2. **Deploy Backend Changes** (platform detection, callbacks)
3. **Test with Debug App Build**
4. **Deploy Mobile App**
5. **Monitor Logs**
6. **Verify All Flows**

---

## 📊 OAuth Flow Diagrams

### Google Sign-In (Mobile)

```
User Clicks "Sign In with Google"
         ↓
WebView detects mobile platform
         ↓
Opens accounts.google.com in Chrome Custom Tab
         ↓
User authenticates
         ↓
Redirects to: gameofcreators://auth/callback?code=xxx
         ↓
Flutter app catches deep link
         ↓
App opens WebView to /choose-username or /dashboard
         ↓
User is signed in
```

### Instagram Connection (Mobile)

```
User Clicks "Connect Instagram"
         ↓
WebView detects mobile platform
         ↓
Opens api.instagram.com/oauth in external browser
         ↓
User authenticates
         ↓
Redirects to: gameofcreators://instagram/success
         ↓
Flutter app catches deep link
         ↓
App reloads /dashboard/settings in WebView
         ↓
Instagram account shows as connected
```

---

## 🔗 Important Links

- **Full Documentation**: [MOBILE_APP_OAUTH_DEEP_LINKING.md](./MOBILE_APP_OAUTH_DEEP_LINKING.md)
- **Google OAuth Setup**: [GOOGLE_OAUTH_SETUP.md](./GOOGLE_OAUTH_SETUP.md)
- **Unified Auth Summary**: [UNIFIED_AUTH_SUMMARY.md](./UNIFIED_AUTH_SUMMARY.md)

---

## 📞 Need Help?

1. Check the full documentation for detailed explanations
2. Review troubleshooting section for common issues
3. Test with debug builds before production
4. Monitor logs during initial rollout

---

**Version**: 1.0.0  
**Last Updated**: December 13, 2025
