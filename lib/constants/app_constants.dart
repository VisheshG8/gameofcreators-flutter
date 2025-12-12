import 'package:flutter/material.dart';

class AppConstants {
  // Website URL
  static const String websiteUrl = 'https://www.gameofcreators.com/';
  static const String websiteDomain = 'gameofcreators.com';

  // App Info
  static const String appName = 'Game of Creators';
  static const String appVersion = '1.0.0';

  // Splash Screen
  static const Duration splashDuration = Duration(seconds: 3);

  // WebView Settings
  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool enableCache = true;

  // Theme Colors
  static const Color primaryColor = Color(0xFFD4AF37);
  static const Color secondaryColor = Color(0xFF9CA3AF);
  static const Color backgroundColor = Color(0xFF1a1a2e);
  static const Color darkBackgroundColor = Color(0xFF0f0f1e);
  static const Color accentColor = Color(0xFFD4AF37);
  static const Color splashBackground = Color(0xFF1F1F3A);
  static const Color textColor = Color(0xFFC7C7D1);

  // Gradient Colors for Splash
  static const List<Color> splashGradientColors = [
    Color(0xFF1F1F3A), // Dark purple/navy
    Color(0xFF1a1a2e),
    Color(0xFF16213e),
  ];

  // Error Messages
  static const String noInternetMessage =
      'No internet connection. Please check your network and try again.';
  static const String loadErrorMessage =
      'Failed to load the page. Please try again.';
  static const String timeoutMessage =
      'Request timed out. Please check your connection.';

  // Double tap to exit
  static const Duration exitWarningDuration = Duration(seconds: 2);
  static const String exitWarningMessage = 'Press back again to exit';

  // Timeouts
  static const Duration pageLoadTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}
