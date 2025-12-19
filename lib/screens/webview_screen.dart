import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import '../constants/app_constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class WebViewScreen extends StatefulWidget {
  final WebViewController? preloadedController;
  final String? initialUrl; // URL to load on cold start (from notification/deep link)

  const WebViewScreen({
    super.key,
    this.preloadedController,
    this.initialUrl,
  });

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
  bool _authInProgress = false;
  bool _optimizationsInjected = false;
  bool _sessionInjected = false;
  bool _youtubeOAuthInProgress = false;
  String? _pendingNotificationUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    // Don't check connectivity on init - let WebView handle it
    // _checkConnectivity() removed - causes false positives
    
    // REMOVED: _initDeepLinks()
    // REASON: Deep links are now handled exclusively by main.dart -> NotificationService
    // This prevents race conditions and ensures a single source of truth.

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
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

    // Set the WebViewController reference in NotificationService for navigation
    // Provide a custom navigation callback that bypasses the navigation delegate
    NotificationService().setWebViewController(
      _webViewController,
      onNavigate: (String url) {
        debugPrint('🔔 Notification callback triggered for: $url');
        debugPrint('🔔 Setting _pendingNotificationUrl and loading request...');
        // Set flag to allow this URL in navigation delegate
        _pendingNotificationUrl = url;
        // Load the URL - the navigation delegate will allow it via _pendingNotificationUrl
        _webViewController.loadRequest(Uri.parse(url));
        debugPrint('🔔 loadRequest() called for: $url');
      },
    );

    // CRITICAL FIX: Check if there's a pending deep link/notification URL from cold start
    // This happens when a notification/deep link was clicked before WebView was ready
    final coldStartUrl = NotificationService().getPendingNotificationUrl();
    if (coldStartUrl != null) {
      debugPrint('❄️ FAST: Cold start deep link URL detected: $coldStartUrl');
      // Set the pending URL immediately - it will be loaded in _loadWebsite()
      _pendingNotificationUrl = coldStartUrl;
      debugPrint('✅ Deep link URL will be loaded instead of home page');
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

              // OPTIMIZATION: Hide loading screen at 50% to show content faster
              // This makes the app feel much faster even if page isn't fully loaded
              // Lower threshold (50% instead of 60%) for faster perceived performance
              if (progress >= 50 && _isLoading) {
                debugPrint('📊 Progress: $progress% - Hiding loading screen');
                _isLoading = false;
              }
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });

            // OPTIMIZATION: Inject performance optimizations as early as possible
            // This happens before DOM is fully loaded for maximum impact
            _injectEarlyPerformanceOptimizations();
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            _updateBackButtonState();

            // Don't interfere with myaccount.google.com - Google may redirect here
            // as an intermediate step before showing the consent screen.
            // Just wait for the actual consent screen or callback.
            if (url.contains('myaccount.google.com') &&
                _youtubeOAuthInProgress) {
              debugPrint(
                '⚠️ On myaccount.google.com during YouTube OAuth - waiting for consent screen or callback',
              );
              // Don't do anything - let Google handle the flow
              // The consent screen should appear next, or Google will redirect to callback
            }

            // Inject session only once if authenticated and on our domain
            if (url.contains(AppConstants.websiteDomain) && !_sessionInjected) {
              await _injectSupabaseSession();
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Only show error for main frame failures (not sub-resources like images, ads, etc.)
            // This prevents false positives from minor resource load failures
            if (error.isForMainFrame ?? true) {
              debugPrint('❌ Main frame error: ${error.description}');
              setState(() {
                _hasError = true;
                _isLoading = false;
                _errorMessage = error.description;
              });
            } else {
              // Log sub-resource errors but don't show error screen
              debugPrint(
                '⚠️ Sub-resource error (ignored): ${error.description}',
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            // PRIORITY 1: Allow navigation from notifications/deep links (bypass all checks)
            if (_pendingNotificationUrl != null) {
              debugPrint('🔔 Deep Link Navigation Request: ${request.url}');
              debugPrint('🔔 Expected Deep Link URL: $_pendingNotificationUrl');

              // Check if this navigation is from our domain
              final isOurDomain = request.url.contains(AppConstants.websiteDomain);

              if (isOurDomain) {
                // FAST: Allow any navigation on our domain and clear the flag
                debugPrint('✅ FAST: Allowing deep link navigation on our domain: ${request.url}');
                _pendingNotificationUrl = null;
                NotificationService().clearPendingNotificationUrl();
                return NavigationDecision.navigate;
              } else {
                // Different domain - block it
                debugPrint('⚠️ Blocked external navigation during deep link: ${request.url}');
                return NavigationDecision.prevent;
              }
            }

            // Detect YouTube OAuth flow start
            if (request.url.contains('/api/youtube/auth')) {
              _youtubeOAuthInProgress = true;
              debugPrint('📺 YouTube OAuth flow started');
            }

            // Detect YouTube OAuth URLs by checking for YouTube scope or callback
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              final scope = uri.queryParameters['scope'] ?? '';
              final redirectUri = uri.queryParameters['redirect_uri'] ?? '';
              if (scope.contains('youtube') ||
                  scope.contains('googleapis.com/auth/youtube') ||
                  redirectUri.contains('youtube/callback')) {
                _youtubeOAuthInProgress = true;
                debugPrint('📺 YouTube OAuth URL detected');
              }
            }

            // IMPORTANT: Don't intercept Google OAuth if we're in YouTube OAuth flow
            // Google uses intermediate URLs like /signin/oauth/delegation that don't
            // have YouTube-specific parameters, but are part of the YouTube OAuth flow
            if (_youtubeOAuthInProgress) {
              debugPrint(
                '📺 YouTube OAuth in progress - allowing Google URLs to continue flow',
              );
              // Allow all Google URLs during YouTube OAuth (they're part of the flow)
              if (request.url.contains('accounts.google.com') ||
                  request.url.contains('myaccount.google.com')) {
                return NavigationDecision.navigate;
              }
            }

            // Intercept Google OAuth URLs and trigger native authentication
            // BUT ONLY if we're NOT in YouTube OAuth flow
            if (!_youtubeOAuthInProgress && _isGoogleOAuthUrl(request.url)) {
              debugPrint(
                '🔐 Google OAuth detected, triggering native auth: ${request.url}',
              );
              _handleNativeGoogleAuth();
              return NavigationDecision.prevent;
            }

            // Allow myaccount.google.com to load - Google may show this as intermediate step
            // before the consent screen. Don't interfere with the flow.
            if (request.url.contains('myaccount.google.com')) {
              debugPrint(
                '⚠️ myaccount.google.com detected - allowing (Google may show consent screen next)',
              );
              return NavigationDecision.navigate;
            }

            // Allow other OAuth URLs to load within webview
            if (_isOAuthUrl(request.url)) {
              debugPrint('✅ Allowing OAuth URL in webview: ${request.url}');
              return NavigationDecision.navigate;
            }

            // Reset YouTube OAuth flag when we reach our callback or settings
            if (request.url.contains('/mobile/youtube/callback') ||
                request.url.contains('/api/youtube/callback') ||
                request.url.contains('/dashboard/settings')) {
              _youtubeOAuthInProgress = false;
            }

            // Handle external links (but allow our own domain and OAuth callbacks)
            if (!request.url.contains(AppConstants.websiteDomain) &&
                !request.url.contains('/auth/callback') &&
                !request.url.contains('/mobile/auth/callback') &&
                !request.url.contains('/api/youtube/callback') &&
                !request.url.contains('/mobile/youtube/callback')) {
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
      final androidController =
          _webViewController.platform as AndroidWebViewController;

      androidController
        ..setMediaPlaybackRequiresUserGesture(false)
        ..setGeolocationPermissionsPromptCallbacks(
          onShowPrompt: (request) async {
            return GeolocationPermissionsResponse(allow: false, retain: false);
          },
        )
        ..setOnShowFileSelector(_androidFilePicker);

      // CRITICAL PERFORMANCE SETTINGS
      androidController.enableZoom(false); // Disable zoom for faster rendering

      // Use a User-Agent that includes our app identifier for backend detection
      // but maintains standard Chrome format for better Google account detection
      // This helps Google recognize the webview and show account picker properly
      androidController.setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 GameOfCreators-Mobile/Android',
      );

      // PERFORMANCE OPTIMIZATION: Advanced caching and performance settings
      androidController.runJavaScript('''
        (function() {
          // Enable AppCache if available
          if (window.applicationCache) {
            window.applicationCache.addEventListener('updateready', function() {
              window.location.reload();
            });
          }

          // Prefetch DNS for common resources
          var dnsPrefetch = ['https://www.google-analytics.com', 'https://fonts.googleapis.com', 'https://fonts.gstatic.com'];
          dnsPrefetch.forEach(function(url) {
            var link = document.createElement('link');
            link.rel = 'dns-prefetch';
            link.href = url;
            document.head.appendChild(link);
          });

          // Enable passive event listeners for better scroll performance
          if (typeof EventTarget !== 'undefined') {
            var originalAddEventListener = EventTarget.prototype.addEventListener;
            EventTarget.prototype.addEventListener = function(type, listener, options) {
              if (type === 'touchstart' || type === 'touchmove' || type === 'wheel' || type === 'mousewheel') {
                if (typeof options === 'boolean') {
                  options = { capture: options, passive: true };
                } else if (typeof options === 'object' && options.passive === undefined) {
                  options.passive = true;
                }
              }
              return originalAddEventListener.call(this, type, listener, options);
            };
          }
        })();
      ''');
    } else if (_webViewController.platform is WebKitWebViewController) {
      final iosController =
          _webViewController.platform as WebKitWebViewController;

      // Use a User-Agent that includes our app identifier for backend detection
      // but maintains standard Safari format for better Google account detection
      // This helps Google recognize the webview and show account picker properly
      iosController.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 GameOfCreators-Mobile/iOS',
      );

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

    // FAST PRIORITY: Determine which URL to load:
    // 1. Pending notification/deep link URL (HIGHEST - from cold start or notification click)
    // 2. Initial URL passed from SplashScreen
    // 3. Default home page
    String urlToLoad;

    if (_pendingNotificationUrl != null) {
      // HIGHEST PRIORITY: Deep link/notification URL
      urlToLoad = _pendingNotificationUrl!;
      debugPrint('🔔 FAST: Loading deep link URL immediately: $urlToLoad');
      // Don't clear _pendingNotificationUrl yet - navigation delegate needs it
      // It will be cleared when navigation succeeds
    } else if (widget.initialUrl != null) {
      // MEDIUM PRIORITY: Initial URL from splash screen
      urlToLoad = widget.initialUrl!;
      debugPrint('❄️ Loading cold start URL from widget: $urlToLoad');
    } else {
      // LOWEST PRIORITY: Default home page
      urlToLoad = AppConstants.websiteUrl;
      debugPrint('🏠 Loading default home page: $urlToLoad');
    }

    debugPrint('⚡ FAST LOAD: Initiating request to: $urlToLoad');
    _webViewController.loadRequest(Uri.parse(urlToLoad));

    _injectMobileOptimizations();
  }

  /// Inject early performance optimizations before DOM is fully loaded
  void _injectEarlyPerformanceOptimizations() {
    // Run critical performance scripts as early as possible
    _webViewController.runJavaScript('''
      (function() {
        // Mark app start time
        window.mobileAppLoadStart = performance.now();

        // AGGRESSIVE: Force lazy loading for ALL images and iframes
        if (document.documentElement) {
          document.documentElement.setAttribute('loading', 'lazy');
        }

        // Intercept image loading to add lazy loading
        var originalCreateElement = document.createElement;
        document.createElement = function(tagName) {
          var element = originalCreateElement.call(document, tagName);
          if (tagName.toLowerCase() === 'img') {
            element.setAttribute('loading', 'lazy');
            element.setAttribute('decoding', 'async');
          } else if (tagName.toLowerCase() === 'iframe') {
            element.setAttribute('loading', 'lazy');
          }
          return element;
        };

        // Reduce image quality for faster loading
        window.addEventListener('DOMContentLoaded', function() {
          var imgs = document.getElementsByTagName('img');
          for (var i = 0; i < imgs.length; i++) {
            if (!imgs[i].hasAttribute('loading')) {
              imgs[i].setAttribute('loading', 'lazy');
              imgs[i].setAttribute('decoding', 'async');
            }
          }
        });

        // Preconnect to critical domains IMMEDIATELY
        var criticalDomains = [
          'https://www.gameofcreators.com',
          'https://rjprmbjqetxkramwbrqo.supabase.co',
          'https://fonts.googleapis.com',
          'https://fonts.gstatic.com'
        ];

        if (document.head) {
          criticalDomains.forEach(function(domain) {
            var link = document.createElement('link');
            link.rel = 'preconnect';
            link.href = domain;
            link.crossOrigin = 'anonymous';
            document.head.appendChild(link);
          });
        }

        console.log('🚀 Early optimizations injected at:', performance.now() - window.mobileAppLoadStart, 'ms');
      })();
    ''');
  }

  /// Inject mobile optimizations to disable zoom and improve UX
  void _injectMobileOptimizations() {
    // Only inject once per session to avoid redundant operations
    if (_optimizationsInjected) return;
    _optimizationsInjected = true;

    // OPTIMIZATION: Inject immediately without delay for faster load
    // Use ultra-lightweight, minified code for instant execution
    _webViewController.runJavaScript('''
      (function() {
        // Fast viewport setup - runs immediately
        var m=document.querySelector('meta[name="viewport"]')||document.createElement('meta');
        m.name='viewport';
        m.content='width=device-width,initial-scale=1,maximum-scale=1,user-scalable=0';
        if(!m.parentNode)document.head.appendChild(m);

        // Prevent zoom gestures
        ['gesturestart','gesturechange','gestureend'].forEach(function(e){
          document.addEventListener(e,function(t){t.preventDefault()},{passive:!1})
        });

        // Double-tap prevention
        var t=0;
        document.addEventListener('touchend',function(e){
          var n=Date.now();
          n-t<=300&&e.preventDefault();
          t=n
        },{passive:!1});

        // Ultra-minified CSS injection for performance
        var s=document.createElement('style');
        s.textContent='*{-webkit-tap-highlight-color:transparent;-webkit-user-select:none}input,textarea,[contenteditable]{-webkit-user-select:text!important}body{overscroll-behavior:none;-webkit-overflow-scrolling:touch}img{-webkit-user-drag:none}';
        document.head.appendChild(s);

        // Preconnect to critical domains for faster resource loading
        ['https://www.gameofcreators.com','https://rjprmbjqetxkramwbrqo.supabase.co'].forEach(function(u){
          var l=document.createElement('link');
          l.rel='preconnect';
          l.href=u;
          document.head.appendChild(l);
        });

        // Performance reporting
        if (typeof window.mobileAppLoadStart !== 'undefined') {
          console.log('Mobile optimizations loaded in:', performance.now() - window.mobileAppLoadStart, 'ms');
        }
      })();
    ''');
  }

  bool _isOAuthUrl(String url) {
    final oauthProviderDomains = [
      'accounts.google.com',
      'myaccount.google.com',
      'appleid.apple.com',
      'www.facebook.com',
      'facebook.com/v',
      'login.microsoftonline.com',
      'github.com/login',
      'api.twitter.com/oauth',
      'twitter.com/i/oauth',
      'discord.com/oauth2',
      'discord.com/api/oauth2',
      'api.instagram.com/oauth',
      'www.instagram.com/oauth',
      'instagram.com/oauth',
    ];
    return oauthProviderDomains.any((domain) => url.contains(domain));
  }

  /// Check if URL is specifically a Google OAuth URL for USER SIGN-IN
  /// (not for third-party integrations like YouTube, Instagram, etc.)
  bool _isGoogleOAuthUrl(String url) {
    // Only intercept if it's a Google OAuth URL AND it's coming from our auth page
    // Exclude YouTube and other OAuth flows by checking the redirect_uri, scope, or state
    if (!url.contains('accounts.google.com')) {
      return false;
    }

    if (!url.contains('/o/oauth2/') && !url.contains('/signin/oauth')) {
      return false;
    }

    // Exclude YouTube OAuth - check for youtube-related parameters in URL
    // YouTube OAuth URLs will have:
    // - scope parameter containing 'youtube' or 'googleapis.com/auth/youtube'
    // - redirect_uri containing 'youtube/callback'
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final scope = uri.queryParameters['scope'] ?? '';
      final redirectUri = uri.queryParameters['redirect_uri'] ?? '';

      // Check if this is YouTube OAuth by scope or redirect URI
      if (scope.contains('youtube') ||
          scope.contains('googleapis.com/auth/youtube') ||
          redirectUri.contains('youtube/callback') ||
          redirectUri.contains('youtube')) {
        debugPrint(
          '📺 YouTube OAuth detected, allowing in webview (scope: $scope, redirect: $redirectUri)',
        );
        return false; // Don't intercept YouTube OAuth
      }
    }

    // Also check URL string directly as fallback
    if (url.contains('youtube') ||
        url.contains('googleapis.com/auth/youtube') ||
        (url.contains('redirect_uri=') && url.contains('youtube'))) {
      debugPrint(
        '📺 YouTube OAuth detected (string check), allowing in webview',
      );
      return false;
    }

    // Exclude Instagram OAuth
    if (url.contains('instagram') ||
        (uri?.queryParameters['redirect_uri'] ?? '').contains('instagram')) {
      return false;
    }

    // This is a user sign-in with Google (Supabase auth)
    return true;
  }

  /// Handle native Google authentication when Google OAuth is detected
  Future<void> _handleNativeGoogleAuth() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signing in with Google...'),
            backgroundColor: AppConstants.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final authService = AuthService();
      final session = await authService.signInWithGoogle();

      if (session == null) {
        // User cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      debugPrint('✅ Native Google auth successful');
      final accessTokenPreview = session.accessToken.length > 20
          ? '${session.accessToken.substring(0, 20)}...'
          : session.accessToken;
      debugPrint('📝 Access Token: $accessTokenPreview');

      if (session.refreshToken != null) {
        final refreshTokenPreview = session.refreshToken!.length > 20
            ? '${session.refreshToken!.substring(0, 20)}...'
            : session.refreshToken!;
        debugPrint('🔄 Refresh Token: $refreshTokenPreview');
      }

      // Reset the flag to allow injection after auth
      _sessionInjected = false;

      // Inject session into WebView
      await _injectSupabaseSession();

      // Don't navigate here - let the JavaScript bridge handle navigation
      // It will check the user profile and navigate to /dashboard or /choose-username

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Native Google auth failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Inject Supabase session into WebView via JavaScript
  Future<void> _injectSupabaseSession() async {
    try {
      final authService = AuthService();
      final session = authService.getCurrentSession();

      if (session == null || session.isExpired) {
        debugPrint('⚠️ No valid session to inject');
        return;
      }

      // Mark as injected to prevent loops
      _sessionInjected = true;

      debugPrint('💉 Injecting Supabase session into WebView');

      // Method 1: JavaScript injection to set session
      // Use the mobile-auth-bridge.js function if available, otherwise set cookies directly
      final jsCode =
          '''
        (function() {
          try {
            const accessToken = '${session.accessToken}';
            const refreshToken = '${session.refreshToken ?? ''}';
            
            // Try to use the mobile auth bridge function if available
            if (typeof window.setSupabaseSessionFromMobile === 'function') {
              console.log('📱 Using mobile auth bridge to set session');
              window.setSupabaseSessionFromMobile(accessToken, refreshToken).then(() => {
                console.log('✅ Session set, triggering auth state update');
                // Trigger a custom event that the website can listen to
                window.dispatchEvent(new CustomEvent('mobile-auth-complete', {
                  detail: { success: true }
                }));
                // Give the website a moment to process, then reload
                setTimeout(() => {
                  window.location.href = window.location.origin;
                }, 500);
              });
            } else {
              // Fallback: Set cookies directly (Supabase SSR will pick them up)
              console.log('🍪 Setting Supabase cookies directly');
              const domain = window.location.hostname;
              const expires = new Date();
              expires.setTime(expires.getTime() + 60 * 60 * 1000); // 1 hour
              
              // Set access token cookie
              document.cookie = 'sb-access-token=' + accessToken + '; domain=' + domain + '; path=/; expires=' + expires.toUTCString() + '; SameSite=Lax; Secure';
              
              // Set refresh token cookie
              if (refreshToken) {
                document.cookie = 'sb-refresh-token=' + refreshToken + '; domain=' + domain + '; path=/; expires=' + expires.toUTCString() + '; SameSite=Lax; Secure';
              }
              
              // Also try to set session via Supabase client if available
              if (typeof window.supabase !== 'undefined' && window.supabase.auth) {
                window.supabase.auth.setSession({
                  access_token: accessToken,
                  refresh_token: refreshToken
                }).then(() => {
                  console.log('✅ Supabase session set via client');
                  // Reload to pick up the new auth state
                  setTimeout(() => {
                    window.location.href = window.location.origin;
                  }, 500);
                }).catch((error) => {
                  console.error('❌ Failed to set session via client:', error);
                  // Reload anyway to pick up cookies
                  setTimeout(() => {
                    window.location.href = window.location.origin;
                  }, 500);
                });
              } else {
                // No Supabase client, just reload to pick up cookies
                setTimeout(() => {
                  window.location.href = window.location.origin;
                }, 500);
              }
            }
          } catch (error) {
            console.error('❌ Error injecting Supabase session:', error);
          }
        })();
      ''';

      await _webViewController.runJavaScript(jsCode);

      // Method 2: Also set cookies as a fallback
      await _setSupabaseCookies(
        session.accessToken,
        session.refreshToken ?? '',
      );
    } catch (e) {
      debugPrint('❌ Error injecting session: $e');
    }
  }

  /// Set Supabase authentication cookies in WebView
  Future<void> _setSupabaseCookies(
    String accessToken,
    String refreshToken,
  ) async {
    try {
      final cookieManager = WebViewCookieManager();

      // Set access token cookie
      await cookieManager.setCookie(
        WebViewCookie(
          name: 'sb-access-token',
          value: accessToken,
          domain: AppConstants.websiteDomain,
          path: '/',
        ),
      );

      // Set refresh token cookie if available
      if (refreshToken.isNotEmpty) {
        await cookieManager.setCookie(
          WebViewCookie(
            name: 'sb-refresh-token',
            value: refreshToken,
            domain: AppConstants.websiteDomain,
            path: '/',
          ),
        );
      }

      debugPrint('✅ Supabase cookies set');
    } catch (e) {
      debugPrint('❌ Error setting cookies: $e');
    }
  }

  /// Handle file selection for WebView uploads
  /// Uses Android Photo Picker (no broad storage permissions needed)
  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    debugPrint('📁 File picker requested');
    debugPrint('📁 Accept types: ${params.acceptTypes}');
    debugPrint('📁 Mode: ${params.mode}');

    try {
      // Show dialog to choose between camera and gallery
      // No permission request needed - image_picker handles it automatically
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

      // Request camera permission only when using camera
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          debugPrint('❌ Camera permission denied');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera permission is required to take photos'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return [];
        }
      }

      // Pick image - image_picker uses Android Photo Picker on Android 13+
      // No READ_MEDIA_IMAGES permission needed!
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

  /// Launch external URLs in system browser
  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // Show instructions to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Opening external link...'),
            backgroundColor: AppConstants.primaryColor,
            duration: const Duration(seconds: 2),
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
            // Close the app instead of just popping the route
            SystemNavigator.pop();
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
    super.dispose();
  }
}
