# Game of Creators - Mobile WebView App

A production-ready Flutter mobile application that wraps the [Game of Creators](https://www.gameofcreators.com/) website in a native WebView experience with enhanced features and optimizations.

## Features

### Core Functionality

- **Full WebView Integration**: Seamless integration with the Game of Creators website
- **Custom Splash Screen**: Animated splash screen with gaming-themed branding (3-second duration)
- **Pull-to-Refresh**: Native pull-to-refresh functionality for easy content updates
- **Progress Indicators**: Linear and circular progress indicators for page loading
- **Smart Navigation**: Handles back button navigation through web history
- **External Link Handling**: Opens external links in system browser automatically

### User Experience

- **Immersive Full-Screen**: Full-screen experience with minimal UI distractions
- **Smooth Animations**: Professional fade and scale animations on splash screen
- **Loading States**: Graceful loading states with progress tracking
- **Material 3 Design**: Modern UI following Material Design 3 guidelines
- **Dark Theme**: Gaming-optimized dark theme with purple/blue gradient

### Error Handling & Network

- **Connectivity Detection**: Real-time network connectivity monitoring
- **No Internet Error**: Dedicated error screen with retry functionality
- **Page Load Errors**: Graceful error handling with user-friendly messages
- **Retry Mechanism**: One-tap retry for failed connections
- **Timeout Handling**: Configurable timeouts with appropriate error messages

### Navigation & Safety

- **Domain Restriction**: Keeps navigation within gameofcreators.com domain
- **Double-Tap Exit**: Prevents accidental app exits with confirmation
- **Web History Navigation**: Back button navigates through web history when available
- **Exit Confirmation**: Snackbar warning before exiting the app

### Platform Configuration

- **Android**:

  - Internet and network state permissions
  - Cleartext traffic enabled
  - Hardware acceleration
  - Minimum SDK 21 (Android 5.0)

- **iOS**:
  - App Transport Security configured
  - Domain-specific security settings
  - Embedded views enabled
  - Portrait orientation only

## Project Structure

```
lib/
├── main.dart                          # App entry point and configuration
├── constants/
│   └── app_constants.dart             # App-wide constants and configuration
├── screens/
│   ├── splash_screen.dart             # Animated splash screen
│   └── webview_screen.dart            # Main WebView with all features
└── widgets/
    ├── error_widget.dart              # Custom error displays
    └── loading_widget.dart            # Loading indicators
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.10.1 or higher)
- Dart SDK (3.10.1 or higher)
- Android Studio / Xcode (for platform-specific builds)
- A device or emulator for testing

### Installation

1. **Clone or navigate to the project directory**

   ```bash
   cd /Users/mohammadhusenzhare/game_of_creator/game_of_creator_mobile
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate splash screen assets (optional)**

   ```bash
   dart run flutter_native_splash:create
   ```

4. **Verify Flutter setup**
   ```bash
   flutter doctor
   ```
   Fix any issues reported by Flutter Doctor before proceeding.

## Running the Application

### Development Mode

**Run on connected device/emulator:**

```bash
flutter run
```

**Run on specific device:**

```bash
flutter devices  # List available devices
flutter run -d <device_id>
```

**Run on Android:**

```bash
flutter run -d android
```

**Run on iOS:**

```bash
flutter run -d ios
```

### Debug Mode with Hot Reload

```bash
flutter run --debug
```

This enables hot reload - press 'r' to reload, 'R' for hot restart.

## Building for Production

### Android (APK)

**Build debug APK:**

```bash
flutter build apk --debug
```

**Build release APK:**

```bash
flutter build apk --release
```

**Build app bundle (for Play Store):**

```bash
flutter build appbundle --release
```

Output location: `build/app/outputs/flutter-apk/app-release.apk`

### Android Signing (for Release)

1. Create a keystore:

   ```bash
   keytool -genkey -v -keystore ~/game-of-creators-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gameofcreators
   ```

2. Create `android/key.properties`:

   ```properties
   storePassword=<your-password>
   keyPassword=<your-password>
   keyAlias=gameofcreators
   storeFile=<path-to-your-jks-file>
   ```

3. Update `android/app/build.gradle.kts` to reference the keystore (add signing configuration).

### iOS (requires macOS)

**Build for device:**

```bash
flutter build ios --release
```

**Build for App Store:**

```bash
flutter build ipa
```

Output location: `build/ios/ipa/`

**Note**: iOS builds require proper provisioning profiles and certificates from Apple Developer account.

## Configuration

### App Constants

Edit `lib/constants/app_constants.dart` to customize:

- Website URL and domain
- Theme colors
- Timeout durations
- Error messages
- Splash duration

### Theme Customization

The app uses a dark theme with the following color scheme:

- Primary: `#6C63FF` (Purple)
- Secondary: `#4E47D8` (Dark Purple)
- Background: `#1a1a2e` (Dark Blue)
- Accent: `#E94560` (Red)

To customize, edit the constants in [app_constants.dart](lib/constants/app_constants.dart).

### Splash Screen

To customize the splash screen:

1. Edit `flutter_native_splash` configuration in `pubspec.yaml`
2. Run: `dart run flutter_native_splash:create`
3. Customize animation in [splash_screen.dart](lib/screens/splash_screen.dart)

## Dependencies

```yaml
dependencies:
  webview_flutter: ^4.13.0 # WebView functionality
  webview_flutter_android: ^3.16.0 # Android-specific WebView
  webview_flutter_wkwebview: ^3.15.0 # iOS-specific WebView
  connectivity_plus: ^6.1.2 # Network connectivity
  url_launcher: ^6.3.1 # External URL handling
  flutter_native_splash: ^2.4.2 # Splash screen generation
```

## Testing

### Run unit tests:

```bash
flutter test
```

### Run integration tests:

```bash
flutter drive --target=test_driver/app.dart
```

### Test on different screen sizes:

```bash
flutter run -d <device_id> --dart-define=SCREEN_SIZE=small
```

## Troubleshooting

### Common Issues

**1. WebView not loading:**

- Check internet connection
- Verify the website URL in `app_constants.dart`
- Check Android permissions in `AndroidManifest.xml`

**2. Build errors:**

```bash
flutter clean
flutter pub get
flutter pub upgrade
```

**3. iOS build issues:**

- Update CocoaPods: `cd ios && pod install`
- Clean build: `cd ios && rm -rf Pods Podfile.lock && pod install`

**4. Splash screen not showing:**

```bash
dart run flutter_native_splash:create
flutter clean
flutter run
```

**5. WebView performance issues:**

- Clear app cache
- Check `enableJavaScript` and `enableDomStorage` settings
- Verify hardware acceleration is enabled (Android)

### Debug Commands

**Check Flutter version:**

```bash
flutter --version
```

**Analyze code for issues:**

```bash
flutter analyze
```

**Format code:**

```bash
flutter format lib/
```

## Performance Optimization

The app includes several optimizations:

- Hardware acceleration enabled (Android)
- WebView caching enabled
- Efficient state management
- Lazy loading of resources
- Optimized images and assets

## App Information

- **App Name**: Game of Creators
- **Package ID (Android)**: com.gameofcreators.mobile
- **Bundle ID (iOS)**: com.gameofcreators.mobile
- **Version**: 1.0.0+1
- **Min SDK (Android)**: 21 (Android 5.0)
- **Target Platform**: Android 10+ / iOS 12+

## Screenshots & Assets

To add custom app icons:

1. Replace icons in `android/app/src/main/res/mipmap-*/ic_launcher.png`
2. Replace icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
3. Or use: `flutter pub run flutter_launcher_icons:main`

## Publishing

### Google Play Store (Android)

1. Complete signing setup
2. Build app bundle: `flutter build appbundle --release`
3. Upload to Google Play Console
4. Complete store listing and submit for review

### Apple App Store (iOS)

1. Configure signing in Xcode
2. Build IPA: `flutter build ipa`
3. Upload to App Store Connect via Xcode or Transporter
4. Complete App Store listing and submit for review

## Support

For issues or questions:

1. Check Flutter documentation: https://flutter.dev/docs
2. Check WebView Flutter plugin: https://pub.dev/packages/webview_flutter
3. Review this README for common solutions

## Development Notes

### Code Quality

- Follows Flutter best practices
- Null safety enabled
- Well-commented and documented
- Material 3 design principles
- Clean architecture pattern

### Future Enhancements

- Push notifications
- Offline mode with cached content
- Deep linking support
- Social sharing integration
- Analytics integration
- In-app updates
