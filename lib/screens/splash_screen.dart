import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/notification_service.dart';
import 'webview_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String? _initialUrl; // URL to load when WebView opens
  bool _coldStartChecked = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Start animation
    _animationController.forward();

    // CRITICAL: Check for cold start URL from NotificationService
    _handleColdStart();
  }

  /// Handle cold start - check if app was opened by deep link or notification
  Future<void> _handleColdStart() async {
    try {
      debugPrint('❄️ Checking for cold start URL...');

      // REMOVED DIRECT CHECK: _appLinks.getInitialLink()
      // REASON: Main.dart already checked this. We don't want to check twice.
      // ONLY check NotificationService (Single Source of Truth)
      final pendingNotificationUrl = NotificationService().getPendingNotificationUrl();
      if (pendingNotificationUrl != null) {
        debugPrint('❄️ Cold start URL found in Service: $pendingNotificationUrl');
        _initialUrl = pendingNotificationUrl;
      } else {
        debugPrint('✅ No cold start URL - will load home page');
      }
    } catch (e) {
      debugPrint('❌ Error checking cold start: $e');
    } finally {
      _coldStartChecked = true;
      _navigateToWebView();
    }
  }

  /// Navigate to WebView after cold start check and splash animation
  void _navigateToWebView() {
    // Wait for minimum splash duration
    Future.delayed(AppConstants.splashDuration, () {
      if (mounted && _coldStartChecked) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              initialUrl: _initialUrl,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.splashBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppConstants.splashGradientColors,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SVG Logo
                Image.asset('assets/logo.png', width: 200, height: 200),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
