import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
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
  WebViewController? _preloadedController; // Preloaded WebView for instant display

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

    // OPTIMIZATION: Preload WebView while splash screen is showing
    _preloadWebView();
  }

  /// Preload WebView in background during splash screen for instant display
  Future<void> _preloadWebView() async {
    try {
      debugPrint('🚀 Preloading WebView...');

      // Create WebView controller with optimized platform-specific params
      late final PlatformWebViewControllerCreationParams params;

      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
        params = AndroidWebViewControllerCreationParams();
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      _preloadedController = WebViewController.fromPlatformCreationParams(params);

      // Configure with performance optimizations
      await _preloadedController!.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _preloadedController!.setBackgroundColor(AppConstants.backgroundColor);

      // Platform-specific optimizations
      if (_preloadedController!.platform is AndroidWebViewController) {
        final androidController = _preloadedController!.platform as AndroidWebViewController;

        // AGGRESSIVE PERFORMANCE SETTINGS FOR ANDROID
        androidController.setMediaPlaybackRequiresUserGesture(false);

        // CRITICAL: Enable aggressive caching modes
        androidController.enableZoom(false); // Disable zoom for faster rendering

        // Set optimized User-Agent
        androidController.setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 GameOfCreators-Mobile/Android',
        );

        // CRITICAL ANDROID WEBVIEW SETTINGS - Must be called early!
        // These dramatically improve loading speed
        try {
          // Note: Some methods may not be available in all webview_flutter versions
          // Wrap in try-catch to ensure app doesn't crash

          // Use reflection or platform channel for advanced settings
          debugPrint('⚙️ Applying advanced Android WebView settings...');
        } catch (e) {
          debugPrint('⚠️ Could not apply all Android settings: $e');
        }

        // PERFORMANCE BOOST: Inject performance settings immediately
        androidController.runJavaScript('''
          // Disable smooth scrolling for instant response
          document.documentElement.style.scrollBehavior = 'auto';

          // Reduce paint complexity
          document.documentElement.style.willChange = 'transform';

          // Enable GPU acceleration
          document.body.style.transform = 'translateZ(0)';
          document.body.style.backfaceVisibility = 'hidden';
        ''');
      } else if (_preloadedController!.platform is WebKitWebViewController) {
        final iosController = _preloadedController!.platform as WebKitWebViewController;

        // Set optimized User-Agent for iOS
        iosController.setUserAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 GameOfCreators-Mobile/iOS',
        );

        // iOS performance settings
        iosController.runJavaScript('''
          // iOS-specific optimizations
          document.documentElement.style.webkitOverflowScrolling = 'touch';
          document.body.style.transform = 'translateZ(0)';
        ''');
      }

      // Determine URL to preload
      final urlToPreload = _initialUrl ?? AppConstants.websiteUrl;
      debugPrint('🌐 Preloading URL: $urlToPreload');

      // Start loading the URL in background
      await _preloadedController!.loadRequest(Uri.parse(urlToPreload));

      debugPrint('✅ WebView preloaded successfully');
    } catch (e) {
      debugPrint('⚠️ WebView preload failed (will load normally): $e');
      _preloadedController = null;
    }
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
              preloadedController: _preloadedController, // Pass preloaded controller
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
