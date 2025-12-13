import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';

class WebViewScreen extends StatefulWidget {
  final WebViewController? preloadedController;

  const WebViewScreen({super.key, this.preloadedController});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _loadingProgress = 0.0;
  bool _canGoBack = false;
  DateTime? _lastBackPressed;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _authInProgress = false;
  bool _optimizationsInjected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _checkConnectivity();
    _initDeepLinks();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When user returns to the app after authentication
    if (state == AppLifecycleState.resumed && _authInProgress) {
      debugPrint('📱 App resumed - checking authentication state');
      _authInProgress = false;

      // Reload the current page to pick up authentication state
      _webViewController.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checking authentication status...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  /// Initialize deep link handling for OAuth callbacks
  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Check if app was opened with a deep link
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      // Handle error
      debugPrint('Failed to get initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Deep link received: $uri');
    debugPrint('🔗 Scheme: ${uri.scheme}');
    debugPrint('🔗 Host: ${uri.host}');
    debugPrint('🔗 Path: ${uri.path}');
    debugPrint('🔗 Query: ${uri.query}');

    // Handle custom scheme (gameofcreators://auth/callback)
    if (uri.scheme == 'gameofcreators' &&
        uri.host == 'auth' &&
        uri.path.contains('/callback')) {
      debugPrint('✅ Custom scheme callback detected');

      final httpsUrl =
          'https://www.gameofcreators.com/auth/callback?${uri.query}';
      debugPrint('📍 Loading HTTPS URL: $httpsUrl');
      _webViewController.loadRequest(Uri.parse(httpsUrl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completing authentication...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Handle HTTPS deep link (https://www.gameofcreators.com/auth/callback)
    if (uri.path.contains('/auth/callback')) {
      debugPrint('✅ HTTPS callback detected - Loading in WebView');
      _webViewController.loadRequest(uri);

      // Show user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completing authentication...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      debugPrint('❌ Not a callback URL');
    }
  }

  void _initializeWebView() {
    if (widget.preloadedController != null) {
      _webViewController = widget.preloadedController!;
      setState(() {
        _isLoading = false;
      });
    } else {
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

      _webViewController = WebViewController.fromPlatformCreationParams(params);
    }

    // Configure the controller
    _webViewController
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
            if (_isOAuthUrl(request.url)) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }

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
      final androidController = _webViewController.platform as AndroidWebViewController;

      androidController
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(allow: false, retain: false);
          },
        )
        ..setOnShowFileSelector(_androidFilePicker);

      // Enable caching for better performance
      androidController.runJavaScript('''
        if (window.applicationCache) {
          window.applicationCache.addEventListener('updateready', function() {
            window.location.reload();
          });
        }
      ''');
    } else if (_webViewController.platform is WebKitWebViewController) {
      // iOS file picker support and optimizations
      // Enable inline media playback (already set in params)
      // iOS WebView handles caching automatically
    }

    if (widget.preloadedController == null) {
      _loadWebsite();
    } else {
      _injectMobileOptimizations();
    }
  }

  void _loadWebsite() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _webViewController.loadRequest(Uri.parse(AppConstants.websiteUrl));

    _injectMobileOptimizations();
  }

  /// Inject mobile optimizations to disable zoom and improve UX
  void _injectMobileOptimizations() {
    // Only inject once per session to avoid redundant operations
    if (_optimizationsInjected) return;
    _optimizationsInjected = true;

    // Inject optimizations immediately without delay for faster load
    _webViewController.runJavaScript('''
      (function() {
        // Quick viewport setup
        var meta = document.querySelector('meta[name="viewport"]') || document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        if (!meta.parentNode) document.head.appendChild(meta);

        // Simplified zoom prevention
        ['gesturestart', 'gesturechange', 'gestureend'].forEach(function(evt) {
          document.addEventListener(evt, function(e) { e.preventDefault(); }, {passive: false});
        });

        // Fast double-tap prevention
        var lastTouch = 0;
        document.addEventListener('touchend', function(e) {
          var now = Date.now();
          if (now - lastTouch <= 300) e.preventDefault();
          lastTouch = now;
        }, {passive: false});

        // Optimized CSS injection
        var style = document.createElement('style');
        style.textContent = '*{-webkit-tap-highlight-color:transparent;-webkit-user-select:none}input,textarea,[contenteditable]{-webkit-user-select:text!important}body{overscroll-behavior:none;-webkit-overflow-scrolling:touch}';
        document.head.appendChild(style);
      })();
    ''');
  }

  bool _isOAuthUrl(String url) {
    final oauthProviderDomains = [
      'accounts.google.com',
      'appleid.apple.com',
      'www.facebook.com',
      'facebook.com/v',
      'login.microsoftonline.com',
      'github.com/login',
      'api.twitter.com/oauth',
      'twitter.com/i/oauth',
      'discord.com/oauth2',
      'discord.com/api/oauth2',
    ];
    return oauthProviderDomains.any((domain) => url.contains(domain));
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

  /// Handle file selection for WebView uploads
  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    debugPrint('📁 File picker requested');
    debugPrint('📁 Accept types: ${params.acceptTypes}');
    debugPrint('📁 Mode: ${params.mode}');

    try {
      // Request permissions
      final permissionStatus = await _requestStoragePermission();
      if (!permissionStatus) {
        debugPrint('❌ Storage permission denied');
        return [];
      }

      // Show dialog to choose between camera and gallery
      if (!mounted) return [];

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        debugPrint('❌ User cancelled image source selection');
        return [];
      }

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('❌ No image selected');
        return [];
      }

      // Convert path to file:// URI format
      final filePath = image.path;
      final fileUri = 'file://$filePath';
      debugPrint('✅ Image selected: $filePath');
      debugPrint('✅ File URI: $fileUri');
      return [fileUri];
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    }
  }

  /// Request storage permission
  Future<bool> _requestStoragePermission() async {
    // For Android 13+ (API 33+), we need READ_MEDIA_IMAGES
    // For older versions, we need READ_EXTERNAL_STORAGE
    if (await Permission.photos.isGranted) {
      return true;
    }

    final status = await Permission.photos.request();
    if (status.isGranted) {
      return true;
    }

    // Fallback for older Android versions
    if (await Permission.storage.isGranted) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Launch external URLs in system browser
  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // Mark that authentication is in progress
      if (_isOAuthUrl(url)) {
        _authInProgress = true;
      }

      // Show instructions to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Opening browser for authentication...\nReturn to app after signing in',
            ),
            backgroundColor: AppConstants.primaryColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback: try with platform default mode
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      _authInProgress = false;
      // If launching fails, show a snackbar to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
                  child: WebViewWidget(controller: _webViewController),
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
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    super.dispose();
  }
}
