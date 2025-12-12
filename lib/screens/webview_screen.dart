import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

/// Main WebView screen with full functionality
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _loadingProgress = 0.0;
  bool _canGoBack = false;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkConnectivity();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Initialize WebView with platform-specific settings
  void _initializeWebView() {
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

    _webViewController = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppConstants.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            _updateBackButtonState();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle external links
            if (!request.url.contains(AppConstants.websiteDomain)) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    // Platform-specific configurations
    if (_webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (_webViewController.platform as AndroidWebViewController)
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(
              allow: false,
              retain: false,
            );
          },
        );
    }

    _loadWebsite();
  }

  /// Load the main website
  void _loadWebsite() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _webViewController.loadRequest(Uri.parse(AppConstants.websiteUrl));

    // Inject CSS to disable zoom and improve mobile experience
    _injectMobileOptimizations();
  }

  /// Inject mobile optimizations to disable zoom and improve UX
  void _injectMobileOptimizations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _webViewController.runJavaScript('''
        (function() {
          // Disable zoom and set viewport
          var metaTag = document.querySelector('meta[name="viewport"]');
          if (metaTag) {
            metaTag.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
          } else {
            metaTag = document.createElement('meta');
            metaTag.name = 'viewport';
            metaTag.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.head.appendChild(metaTag);
          }

          // Prevent pinch zoom gestures
          document.addEventListener('gesturestart', function(e) {
            e.preventDefault();
          });

          document.addEventListener('gesturechange', function(e) {
            e.preventDefault();
          });

          document.addEventListener('gestureend', function(e) {
            e.preventDefault();
          });

          // Prevent double-tap zoom
          var lastTouchEnd = 0;
          document.addEventListener('touchend', function(event) {
            var now = Date.now();
            if (now - lastTouchEnd <= 300) {
              event.preventDefault();
            }
            lastTouchEnd = now;
          }, false);

          // Add CSS to prevent text selection and improve touch
          var style = document.createElement('style');
          style.innerHTML = `
            * {
              -webkit-touch-callout: none;
              -webkit-user-select: none;
              -moz-user-select: none;
              -ms-user-select: none;
              user-select: none;
              -webkit-tap-highlight-color: transparent;
            }

            input, textarea, [contenteditable] {
              -webkit-user-select: text !important;
              -moz-user-select: text !important;
              -ms-user-select: text !important;
              user-select: text !important;
            }

            body {
              overscroll-behavior: none;
              -webkit-overflow-scrolling: touch;
            }
          `;
          document.head.appendChild(style);
        })();
      ''');
    });
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = AppConstants.noInternetMessage;
      });
    }
  }

  /// Launch external URLs in system browser
  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Update back button state
  Future<void> _updateBackButtonState() async {
    final canGoBack = await _webViewController.canGoBack();
    setState(() {
      _canGoBack = canGoBack;
    });
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    // If WebView can go back, navigate back in web history
    if (_canGoBack) {
      await _webViewController.goBack();
      _updateBackButtonState();
      return false;
    }

    // Double-tap to exit confirmation
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > AppConstants.exitWarningDuration) {
      _lastBackPressed = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppConstants.exitWarningMessage),
          duration: AppConstants.exitWarningDuration,
          backgroundColor: AppConstants.primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return false;
    }

    return true;
  }

  /// Refresh WebView
  Future<void> _refreshWebView() async {
    await _webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // WebView or Error Widget
              if (_hasError)
                _buildErrorWidget()
              else
                RefreshIndicator(
                  onRefresh: _refreshWebView,
                  color: AppConstants.primaryColor,
                  child: WebViewWidget(
                    controller: _webViewController,
                  ),
                ),

              // Loading indicator with progress
              if (_isLoading && !_hasError)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress : null,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor,
                    ),
                    minHeight: 3,
                  ),
                ),

              // Initial loading overlay
              if (_isLoading && _loadingProgress < 0.3)
                LoadingWidget(
                  message: 'Loading ${AppConstants.appName}...',
                  progress: _loadingProgress,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build error widget based on error type
  Widget _buildErrorWidget() {
    if (_errorMessage?.contains('net::') ?? false) {
      return NoInternetWidget(onRetry: _loadWebsite);
    }
    return PageLoadErrorWidget(
      onRetry: _loadWebsite,
      errorMessage: _errorMessage,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
