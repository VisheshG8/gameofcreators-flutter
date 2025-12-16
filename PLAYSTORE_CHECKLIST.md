# Play Store Launch Checklist

## ✅ Completed Technical Setup

### 1. App Signing & Security
- ✅ **Keystore Created**: `android/app/upload-keystore.jks`
  - Password: `gameofcreators2024`
  - Alias: `gameofcreators`
  - Validity: 10,000 days
  - **⚠️ BACKUP THIS FILE! Store it securely outside the project.**

- ✅ **Key Properties Configured**: `android/key.properties`
  - **⚠️ NEVER commit this file to git (already in .gitignore)**

- ✅ **Release Signing Configured**: Updated `build.gradle.kts`
  - ProGuard/R8 minification enabled
  - Resource shrinking enabled
  - Release signing configuration added

- ✅ **ProGuard Rules Created**: `android/app/proguard-rules.pro`
  - Flutter-specific rules
  - Plugin rules (WebView, Google Sign-In, Supabase, OneSignal, etc.)

### 2. SDK & Versions
- ✅ **minSdk**: Set to 24 (Android 7.0+) - covers 96%+ devices
- ✅ **targetSdk**: Set to 35 (Android 15) - meets Play Store requirements
- ✅ **App Version**: 1.0.0+1 (from pubspec.yaml)
- ✅ **Application ID**: com.gameofcreators.mobile

### 3. Security Fixes
- ✅ **Cleartext Traffic**: Disabled (`usesCleartextTraffic="false"`)
- ✅ **HTTPS Only**: App now only uses secure connections

### 4. Bug Fixes
- ✅ **Splash Screen Color**: Fixed typo in `pubspec.yaml` (#000000)

### 5. Deep Linking Setup
- ✅ **Asset Links JSON Created**: `assetlinks.json`
  - SHA256 Fingerprint: `B1:5F:1A:6D:A1:53:85:29:EA:FD:02:DC:40:45:9C:92:E5:4D:69:73:E2:F4:10:D9:F0:29:49:BF:05:AA:6B:85`
  - **📌 ACTION REQUIRED**: Upload this file to your website

---

## 📋 Next Steps - Before Building

### Step 1: Test the Configuration
```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Test debug build
flutter build apk --debug

# Test release build (this will use your new keystore)
flutter build apk --release
```

### Step 2: Upload Asset Links File
**CRITICAL for Deep Linking to work!**

Upload the `assetlinks.json` file to BOTH of these URLs:
- `https://www.gameofcreators.com/.well-known/assetlinks.json`
- `https://gameofcreators.com/.well-known/assetlinks.json`

The file MUST be:
- Accessible via HTTPS
- Return `Content-Type: application/json`
- Return HTTP 200 status

**Verification Command:**
```bash
curl -i https://www.gameofcreators.com/.well-known/assetlinks.json
```

---

## 🚀 Building for Play Store

### Build App Bundle (Recommended)
```bash
flutter build appbundle --release
```
**Output**: `build/app/outputs/bundle/release/app-release.aab`

### Build APK (Alternative)
```bash
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk`

**⚠️ Use App Bundle (.aab) for Play Store - it's 15-20% smaller!**

---

## 📝 Play Console Setup Required

### 1. Create Developer Account
- Sign up at [Google Play Console](https://play.google.com/console)
- Pay $25 one-time registration fee
- Complete developer profile

### 2. Create New App
- Click "Create app" in Play Console
- Enter app details:
  - **App name**: Game of Creators
  - **Default language**: English (US)
  - **App or Game**: Game
  - **Free or Paid**: Free

### 3. Store Listing (Required)
Create these assets:

**App Icon** (512 x 512 px)
- High-res version of your launcher icon
- PNG format, no transparency

**Feature Graphic** (1024 x 500 px)
- Main promotional banner
- PNG or JPEG

**Screenshots** (At least 2 required)
- Phone: Min 320px, max 3840px on shortest side
- Tablet (optional): Min 320px on shortest side
- Take screenshots from different app sections

**Description**
- Short description (80 characters max)
- Full description (4000 characters max)
- Include keywords for ASO (App Store Optimization)

**Categorization**
- Application type: Game
- Category: Casual / Strategy / Other (your choice)
- Content rating: Complete IARC questionnaire

### 4. Privacy Policy (REQUIRED)
**⚠️ MANDATORY - Your app collects user data!**

Your app uses:
- OneSignal (push notifications)
- Supabase (authentication, user data)
- Google Sign-In (user profile)
- Camera & Storage permissions

**You MUST**:
1. Create a privacy policy explaining:
   - What data you collect
   - How you use it
   - How you protect it
   - User rights (access, deletion)
2. Host it online (your website)
3. Add URL to Play Console

**Template sections needed**:
- Information We Collect
- How We Use Information
- Third-Party Services (OneSignal, Supabase, Google)
- Data Security
- User Rights
- Contact Information

### 5. Data Safety Form (REQUIRED)
In Play Console > Data safety, declare:

**Data collected**:
- Personal info (name, email via Google Sign-In)
- Device IDs (for push notifications)
- App activity

**Data usage**:
- App functionality
- Authentication
- Push notifications

**Data sharing**:
- With third parties: Yes (OneSignal, Supabase)

**Security practices**:
- Data encrypted in transit (HTTPS)
- Users can request deletion
- Follows security best practices

### 6. Content Rating
Complete the IARC questionnaire:
- Answer questions about violence, inappropriate content
- Based on gaming content
- Determines age rating (ESRB, PEGI, etc.)

### 7. Target Audience
- Select age groups your app targets
- If under 13, additional COPPA compliance required

### 8. App Access
- Does your app require login? **YES**
- Provide test credentials for reviewers

### 9. Advertising
- Does your app show ads? (Specify)
- If yes, declare ad providers

---

## 🧪 Testing Before Submission

### Internal Testing Track
1. Upload your .aab to Internal Testing
2. Add testers (email addresses)
3. Test for at least 14 days
4. Monitor crashes in Play Console

### Recommended Tests
- ✅ App installs and opens
- ✅ Google Sign-In works
- ✅ Push notifications work
- ✅ Deep links work (from website, notifications)
- ✅ Camera/file uploads work
- ✅ App doesn't crash
- ✅ Performance is good
- ✅ No memory leaks
- ✅ Works on different devices/Android versions

### Test Devices
Test on multiple:
- Android versions (7.0 to 15)
- Screen sizes (small, medium, large)
- Manufacturers (Samsung, Pixel, OnePlus, etc.)

**Use Firebase Test Lab**: Free tier available in Play Console

---

## 📤 Submission Checklist

Before submitting to Production:

- [ ] App bundle built and tested
- [ ] Privacy policy created and hosted
- [ ] Data safety form completed
- [ ] Store listing complete (descriptions, screenshots, icon)
- [ ] Content rating obtained
- [ ] Internal testing completed (14+ days recommended)
- [ ] No critical bugs or crashes
- [ ] Asset links file uploaded to website
- [ ] Test credentials provided (if login required)
- [ ] App follows [Play Store policies](https://play.google.com/about/developer-content-policy/)

---

## 🔐 Security Reminders

### NEVER Commit to Git
- ❌ `android/key.properties`
- ❌ `android/app/upload-keystore.jks`
- ❌ `android/local.properties`

These are already in `.gitignore`, but double-check!

### Backup Your Keystore
**⚠️ CRITICAL**: If you lose your keystore, you can NEVER update your app again!

**Backup locations**:
1. Secure cloud storage (encrypted)
2. External hard drive
3. Password manager (if supports file storage)

**What to backup**:
- `upload-keystore.jks` file
- Keystore password: `gameofcreators2024`
- Key alias: `gameofcreators`
- Key password: `gameofcreators2024`

---

## 📊 Post-Launch

### Monitor
- Crashes & ANRs in Play Console
- User reviews and ratings
- Download statistics

### Update Strategy
For future updates:
1. Increment version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # 1.0.1 is version name, 2 is version code
   ```
2. Build new app bundle
3. Upload to Play Console
4. Submit for review

### Useful Commands
```bash
# Check your keystore
keytool -list -v -keystore android/app/upload-keystore.jks -alias gameofcreators

# Build release
flutter build appbundle --release

# Analyze app size
flutter build apk --release --analyze-size

# Check for issues
flutter doctor -v
flutter analyze
```

---

## 📚 Additional Resources

- [Google Play Console](https://play.google.com/console)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)
- [Data Safety Requirements](https://support.google.com/googleplay/android-developer/answer/10787469)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)

---

## 🆘 Troubleshooting

### Build Fails After Changes
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
flutter build appbundle --release
```

### ProGuard Issues
Check `android/app/proguard-rules.pro` and add rules for any missing classes.

### Deep Links Not Working
1. Verify assetlinks.json is accessible
2. Check SHA256 fingerprint matches
3. Test with: `adb shell am start -a android.intent.action.VIEW -d "https://www.gameofcreators.com/your-path"`

### Signing Errors
- Verify `android/key.properties` exists
- Check file paths are correct
- Ensure keystore file is at `android/app/upload-keystore.jks`

---

**Good luck with your Play Store launch! 🚀**
