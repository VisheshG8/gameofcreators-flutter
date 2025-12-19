import 'package:flutter/material.dart';

class AppConstants {
  // Website URL
  static const String websiteUrl = 'https://www.gameofcreators.com/';
  static const String websiteDomain = 'gameofcreators.com';

  // App Info
  static const String appName = 'Game of Creators';
  static const String appVersion = '1.0.5';

  // Splash Screen
  static const Duration splashDuration = Duration(milliseconds: 2000); // Reduced from 3s to 2s for faster load

  // WebView Settings
  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool enableCache = true;

  // WebView Performance Optimizations
  static const bool enableWebViewPreloading = true; // Preload WebView during splash
  static const bool enableResourceBlocking = false; // Block third-party resources (ads, trackers)
  static const bool enableDNSPrefetch = true; // Prefetch DNS for faster resource loading
  static const bool enablePassiveEventListeners = true; // Better scroll performance

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

  // Supabase Configuration
  // TODO: Replace with your actual Supabase URL and anon key
  // Get these from: https://app.supabase.com/project/_/settings/api
  static const String supabaseUrl = 'https://rjprmbjqetxkramwbrqo.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqcHJtYmpxZXR4a3JhbXdicnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NzUyMjYsImV4cCI6MjA2MDQ1MTIyNn0._jq3BVcbk-6q1g5bkjZVQqLFLU5fPd3CZyIjpMrLqvs';

  // Google Sign-In Configuration
  // TODO: Replace with your Web Client ID from Google Cloud Console
  // This should be the Web Client ID (not Android/iOS client ID)
  // Get it from: https://console.cloud.google.com/apis/credentials
  static const String googleWebClientId =
      '942484778913-sfo3qenvqmdlcu1c6sshr20dluj6p53p.apps.googleusercontent.com';
}
