# Mobile OAuth Deep Linking - Implementation Checklist

Use this checklist to track your progress implementing mobile OAuth deep linking.

---

## 📋 Phase 1: Backend Configuration

### Environment Setup
- [ ] Add `NEXT_PUBLIC_MOBILE_SCHEME=gameofcreators` to `.env`
- [ ] Verify all OAuth credentials are present in `.env`
- [ ] Test environment variables loading correctly

### Platform Detection
- [ ] Create `lib/platform-utils.ts` with detection functions
- [ ] Implement `detectPlatform()` function
- [ ] Implement `getRedirectUri()` function
- [ ] Add TypeScript types for Platform enum

### Google OAuth Updates
- [ ] Update `components/auth/SignInPage.tsx`
  - [ ] Add mobile platform detection
  - [ ] Update `handleGoogleSignIn()` with mobile redirect URI
  - [ ] Test on local development
- [ ] Update `components/auth/SignUpPage.tsx`
  - [ ] Add mobile platform detection
  - [ ] Update `handleGoogleSignUp()` with mobile redirect URI
  - [ ] Test on local development

### Instagram OAuth Updates
- [ ] Update `app/dashboard/settings/client.tsx`
  - [ ] Add mobile platform detection to `handleInstagramConnect()`
  - [ ] Update redirect URI for mobile
  - [ ] Add sessionStorage flag for auth pending
  - [ ] Test on local development

### YouTube OAuth Updates
- [ ] Update `app/dashboard/settings/client.tsx`
  - [ ] Add mobile platform detection to `handleYouTubeConnect()`
  - [ ] Pass platform parameter to API
  - [ ] Add sessionStorage flag for auth pending
- [ ] Create `app/api/youtube/auth/route.ts`
  - [ ] Implement POST handler
  - [ ] Add platform parameter support
  - [ ] Generate auth URL with correct redirect URI
  - [ ] Set state cookie for CSRF protection
  - [ ] Test API endpoint

### Callback Route Updates
- [ ] Update `app/auth/callback/route.ts`
  - [ ] Add user agent detection
  - [ ] Add mobile redirect logic
  - [ ] Test with mock mobile user agent
- [ ] Update `app/api/instagram/callback/route.ts`
  - [ ] Add user agent detection
  - [ ] Add mobile redirect logic
  - [ ] Test with mock mobile user agent
- [ ] Update `app/api/youtube/callback/route.ts`
  - [ ] Add user agent detection
  - [ ] Add mobile redirect logic
  - [ ] Test with mock mobile user agent

### Testing Backend Locally
- [ ] Test Google OAuth with web user agent
- [ ] Test Google OAuth with mobile user agent (mock)
- [ ] Test Instagram with web user agent
- [ ] Test Instagram with mobile user agent (mock)
- [ ] Test YouTube with web user agent
- [ ] Test YouTube with mobile user agent (mock)

---

## 📋 Phase 2: OAuth Provider Configuration

### Google Cloud Console
- [ ] Log in to [Google Cloud Console](https://console.cloud.google.com/)
- [ ] Select Game of Creators project
- [ ] Navigate to APIs & Services > Credentials
- [ ] Edit OAuth 2.0 Client ID
- [ ] Add authorized redirect URIs:
  - [ ] `gameofcreators://auth/callback`
  - [ ] `gameofcreators://youtube/callback`
- [ ] Save changes
- [ ] Test with OAuth 2.0 Playground (optional)
- [ ] Document client ID for reference

### Instagram App (Meta for Developers)
- [ ] Log in to [Meta for Developers](https://developers.facebook.com/)
- [ ] Select Instagram app
- [ ] Navigate to Instagram Basic Display > Settings
- [ ] Add valid OAuth redirect URIs:
  - [ ] `gameofcreators://instagram/callback`
  - [ ] `gameofcreators://instagram/success`
- [ ] Save changes
- [ ] Note: May need app review if changing permissions
- [ ] Document app ID for reference

### Supabase Configuration
- [ ] Log in to [Supabase Dashboard](https://supabase.com/dashboard)
- [ ] Select Game of Creators project
- [ ] Navigate to Authentication > URL Configuration
- [ ] Add redirect URLs:
  - [ ] `gameofcreators://auth/callback`
  - [ ] `gameofcreators://auth/success`
- [ ] Navigate to Authentication > Providers
- [ ] Verify Google provider is enabled
- [ ] Save all changes
- [ ] Test auth in Supabase UI (optional)

---

## 📋 Phase 3: Flutter Mobile App Setup

### Project Setup
- [ ] Create new Flutter project or navigate to existing one
- [ ] Update `pubspec.yaml` with dependencies:
  - [ ] `flutter_inappwebview: ^6.0.0`
  - [ ] `uni_links: ^0.5.1`
  - [ ] `url_launcher: ^6.2.0`
- [ ] Run `flutter pub get`
- [ ] Verify no dependency conflicts

### Android Configuration
- [ ] Open `android/app/src/main/AndroidManifest.xml`
- [ ] Add deep link intent filter inside `<activity>`:
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
- [ ] Save file
- [ ] Test deep link with ADB:
  ```bash
  adb shell am start -W -a android.intent.action.VIEW -d "gameofcreators://auth/callback?code=test"
  ```
- [ ] Verify app opens (should crash if not handled yet, that's OK)

### iOS Configuration
- [ ] Open `ios/Runner/Info.plist` in Xcode or text editor
- [ ] Add URL types:
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
- [ ] Add query schemes (if not present):
  ```xml
  <key>LSApplicationQueriesSchemes</key>
  <array>
    <string>https</string>
    <string>http</string>
  </array>
  ```
- [ ] Save file
- [ ] Test deep link with Simulator:
  ```bash
  xcrun simctl openurl booted "gameofcreators://auth/callback?code=test"
  ```

### Deep Link Service Implementation
- [ ] Create `lib/services/deep_link_service.dart`
- [ ] Implement `DeepLinkService` class
- [ ] Add `initialize()` method
- [ ] Add `_handleDeepLink()` method
- [ ] Add callback functions:
  - [ ] `onAuthCallback`
  - [ ] `onInstagramCallback`
  - [ ] `onYouTubeCallback`
- [ ] Add `dispose()` method
- [ ] Test with sample deep link

### WebView Screen Implementation
- [ ] Create `lib/screens/webview_screen.dart`
- [ ] Implement `WebViewScreen` widget
- [ ] Add `InAppWebView` widget with options:
  - [ ] Set custom user agent: `GameOfCreators-Mobile/Android` or `GameOfCreators-Mobile/iOS`
  - [ ] Enable JavaScript
  - [ ] Add `shouldOverrideUrlLoading` handler
- [ ] Implement `_isOAuthUrl()` helper function
- [ ] Implement deep link callback handlers:
  - [ ] `_handleAuthCallback()`
  - [ ] `_handleSocialCallback()`
- [ ] Add loading indicator
- [ ] Test WebView loads correctly

### Main App Entry Point
- [ ] Update `lib/main.dart`
- [ ] Add `WebViewScreen` as home page
- [ ] Set initial URL to `https://gameofcreators.com`
- [ ] Configure app theme
- [ ] Test app launches correctly

### Testing Flutter App Locally
- [ ] Run on Android emulator: `flutter run`
- [ ] Run on iOS simulator: `flutter run`
- [ ] Test WebView loads website
- [ ] Test custom user agent is set (check in web console)
- [ ] Test deep link opens app (use ADB/xcrun commands)
- [ ] Test OAuth URLs open in external browser
- [ ] Test app doesn't crash on deep link

---

## 📋 Phase 4: Integration Testing

### Google Sign-In Testing
- [ ] **Web Test (Control)**:
  - [ ] Open `https://gameofcreators.com/auth/signin` in browser
  - [ ] Click "Continue with Google"
  - [ ] Complete authentication
  - [ ] Verify redirect to dashboard
  - [ ] Verify user is signed in
- [ ] **Mobile Test**:
  - [ ] Open Flutter app
  - [ ] Navigate to sign-in page
  - [ ] Click "Continue with Google"
  - [ ] Verify OAuth opens in external browser (Chrome Custom Tab/Safari)
  - [ ] Complete authentication
  - [ ] Verify deep link catches: `gameofcreators://auth/callback`
  - [ ] Verify redirects to dashboard or username page
  - [ ] Verify user is signed in in WebView

### Google Sign-Up Testing
- [ ] **Web Test (Control)**:
  - [ ] Open `https://gameofcreators.com/auth/signup`
  - [ ] Click "Continue with Google"
  - [ ] Complete authentication
  - [ ] Complete profile setup
  - [ ] Verify redirect to dashboard
- [ ] **Mobile Test**:
  - [ ] Open Flutter app
  - [ ] Navigate to sign-up page
  - [ ] Click "Continue with Google"
  - [ ] Complete authentication
  - [ ] Verify deep link is caught
  - [ ] Complete profile setup in WebView
  - [ ] Verify redirect to dashboard
  - [ ] Verify account created

### Instagram Connection Testing
- [ ] **Web Test (Control)**:
  - [ ] Sign in to dashboard
  - [ ] Go to Settings > Social Accounts
  - [ ] Click "Connect Instagram"
  - [ ] Authenticate on Instagram
  - [ ] Verify redirect to settings
  - [ ] Verify Instagram account shown as connected
- [ ] **Mobile Test**:
  - [ ] Open Flutter app and sign in
  - [ ] Navigate to Settings
  - [ ] Click "Connect Instagram"
  - [ ] Verify OAuth opens in external browser
  - [ ] Complete Instagram authentication
  - [ ] Verify deep link: `gameofcreators://instagram/success`
  - [ ] Verify settings page reloads
  - [ ] Verify Instagram account shown as connected
  - [ ] Check profile picture and username display

### YouTube Connection Testing
- [ ] **Web Test (Control)**:
  - [ ] Sign in to dashboard
  - [ ] Go to Settings > Social Accounts
  - [ ] Click "Connect YouTube"
  - [ ] Authenticate with Google
  - [ ] Grant YouTube permissions
  - [ ] Verify redirect to settings
  - [ ] Verify YouTube channel shown as connected
- [ ] **Mobile Test**:
  - [ ] Open Flutter app and sign in
  - [ ] Navigate to Settings
  - [ ] Click "Connect YouTube"
  - [ ] Verify OAuth opens in external browser
  - [ ] Complete Google authentication
  - [ ] Grant YouTube permissions
  - [ ] Verify deep link: `gameofcreators://youtube/success`
  - [ ] Verify settings page reloads
  - [ ] Verify YouTube channel shown as connected
  - [ ] Check channel name and subscriber count display

### Edge Case Testing
- [ ] **User Cancels OAuth**:
  - [ ] Start OAuth flow
  - [ ] Press back/cancel button
  - [ ] Verify app returns gracefully (no crash)
  - [ ] Verify can retry authentication
- [ ] **OAuth Error**:
  - [ ] Simulate OAuth error (revoke permissions, etc.)
  - [ ] Verify error message displayed
  - [ ] Verify can retry
- [ ] **Network Error**:
  - [ ] Disconnect internet
  - [ ] Try OAuth flow
  - [ ] Verify error handling
  - [ ] Reconnect and retry
- [ ] **Token Expiry**:
  - [ ] Wait for token to expire (or manually expire)
  - [ ] Verify auto-refresh triggers
  - [ ] Verify no user action needed
- [ ] **Multiple Connections**:
  - [ ] Connect Instagram
  - [ ] Connect YouTube
  - [ ] Verify both show as connected
  - [ ] Disconnect one
  - [ ] Verify other still connected
- [ ] **App Backgrounding**:
  - [ ] Start OAuth flow
  - [ ] Background app during OAuth
  - [ ] Complete OAuth
  - [ ] Foreground app
  - [ ] Verify deep link still works

---

## 📋 Phase 5: Platform-Specific Testing

### Android Testing
- [ ] Test on Android 11 or higher
- [ ] Test on Android 10
- [ ] Test on Android 9
- [ ] Test on physical device (not just emulator)
- [ ] Test on different manufacturers (Samsung, Google, OnePlus)
- [ ] Test deep links from different states:
  - [ ] App in foreground
  - [ ] App in background
  - [ ] App completely closed
- [ ] Verify Chrome Custom Tabs open correctly
- [ ] Test with different browsers as default

### iOS Testing
- [ ] Test on iOS 16 or higher
- [ ] Test on iOS 15
- [ ] Test on iOS 14
- [ ] Test on physical device (not just simulator)
- [ ] Test on different devices (iPhone, iPad)
- [ ] Test deep links from different states:
  - [ ] App in foreground
  - [ ] App in background
  - [ ] App completely closed
- [ ] Verify Safari in-app browser opens correctly
- [ ] Test with Safari as default browser

---

## 📋 Phase 6: Monitoring & Analytics

### Logging Setup
- [ ] Add logging for OAuth initiation:
  - [ ] Log platform detection
  - [ ] Log redirect URI used
  - [ ] Log user agent
- [ ] Add logging for OAuth callbacks:
  - [ ] Log successful authentications
  - [ ] Log failed authentications
  - [ ] Log error types
- [ ] Add logging for deep links:
  - [ ] Log deep link received
  - [ ] Log deep link parameters
  - [ ] Log processing result

### Error Tracking
- [ ] Set up error tracking service (Sentry, Firebase Crashlytics, etc.)
- [ ] Track OAuth errors
- [ ] Track deep link errors
- [ ] Set up alerts for high error rates
- [ ] Create dashboard for monitoring

### Analytics
- [ ] Track OAuth flow completion rates
- [ ] Track platform distribution (web vs mobile)
- [ ] Track authentication method (Google vs email)
- [ ] Track social account connections
- [ ] Track drop-off points in OAuth flow

---

## 📋 Phase 7: Documentation & Handoff

### Internal Documentation
- [ ] Document environment variables needed
- [ ] Document deep link scheme and structure
- [ ] Document OAuth provider configuration
- [ ] Document testing procedures
- [ ] Create troubleshooting guide for support team

### User-Facing Documentation
- [ ] Update help center with mobile app instructions
- [ ] Add FAQ for mobile OAuth
- [ ] Create troubleshooting guide for users
- [ ] Add app store listing with OAuth features

### Developer Handoff
- [ ] Code review completed
- [ ] All tests passing
- [ ] Documentation reviewed
- [ ] Deployment plan created
- [ ] Rollback plan created
- [ ] Knowledge transfer completed

---

## 📋 Phase 8: Pre-Production

### Security Review
- [ ] Review deep link validation
- [ ] Review state parameter implementation
- [ ] Review token storage (should be server-side only)
- [ ] Review rate limiting on OAuth endpoints
- [ ] Review SSL/TLS configuration
- [ ] Penetration testing (optional but recommended)

### Performance Testing
- [ ] Load test OAuth endpoints
- [ ] Test with slow network
- [ ] Test with intermittent connectivity
- [ ] Optimize WebView performance
- [ ] Minimize app size

### Compliance
- [ ] Review GDPR compliance
- [ ] Review CCPA compliance
- [ ] Update privacy policy
- [ ] Update terms of service
- [ ] Get legal approval if needed

---

## 📋 Phase 9: Production Deployment

### Pre-Deployment
- [ ] All tests passing
- [ ] Code merged to main branch
- [ ] OAuth providers configured in production
- [ ] Environment variables set in production
- [ ] Backup current production state
- [ ] Create rollback plan

### Deployment Steps
1. [ ] **Update OAuth Providers**:
   - [ ] Google Cloud Console (add production URIs)
   - [ ] Meta for Developers (add production URIs)
   - [ ] Supabase Dashboard (add production URIs)
2. [ ] **Deploy Backend**:
   - [ ] Deploy to staging first
   - [ ] Test all flows on staging
   - [ ] Deploy to production
   - [ ] Verify deployment successful
3. [ ] **Release Mobile App**:
   - [ ] Build release APK/IPA
   - [ ] Test release build locally
   - [ ] Upload to Google Play Console
   - [ ] Upload to App Store Connect
   - [ ] Submit for review
4. [ ] **Monitor Deployment**:
   - [ ] Monitor error logs
   - [ ] Monitor analytics
   - [ ] Check user feedback
   - [ ] Be ready for hotfix if needed

### Post-Deployment
- [ ] Verify all OAuth flows work in production
- [ ] Monitor error rates for 24 hours
- [ ] Check analytics dashboards
- [ ] Collect user feedback
- [ ] Address any issues immediately
- [ ] Schedule post-deployment review meeting

---

## 📋 Phase 10: Ongoing Maintenance

### Regular Checks
- [ ] Weekly: Review error logs
- [ ] Weekly: Check OAuth completion rates
- [ ] Monthly: Review token refresh rates
- [ ] Monthly: Check for OAuth provider updates
- [ ] Quarterly: Security audit
- [ ] Quarterly: Performance review

### Updates & Improvements
- [ ] Monitor OAuth provider deprecation notices
- [ ] Keep dependencies up to date
- [ ] Improve error messages based on user feedback
- [ ] Add new OAuth providers if needed
- [ ] Optimize performance based on metrics

---

## ✅ Sign-Off

### Development Team
- [ ] Backend Developer: _______________  Date: ___________
- [ ] Mobile Developer: _______________  Date: ___________
- [ ] QA Engineer: _______________  Date: ___________

### Management
- [ ] Product Manager: _______________  Date: ___________
- [ ] Engineering Manager: _______________  Date: ___________

### Production Release
- [ ] Production Deploy: _______________  Date: ___________
- [ ] Post-Deploy Verification: _______________  Date: ___________

---

## 📊 Completion Status

**Overall Progress**: ___ / 200+ items completed

### Phase Completion
- [ ] Phase 1: Backend Configuration (0/30)
- [ ] Phase 2: OAuth Provider Configuration (0/20)
- [ ] Phase 3: Flutter Mobile App Setup (0/45)
- [ ] Phase 4: Integration Testing (0/50)
- [ ] Phase 5: Platform-Specific Testing (0/25)
- [ ] Phase 6: Monitoring & Analytics (0/15)
- [ ] Phase 7: Documentation & Handoff (0/10)
- [ ] Phase 8: Pre-Production (0/15)
- [ ] Phase 9: Production Deployment (0/20)
- [ ] Phase 10: Ongoing Maintenance (0/10)

---

**Document Version**: 1.0.0  
**Last Updated**: December 13, 2025  
**Next Review Date**: _____________
