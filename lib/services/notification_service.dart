import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/app_notification.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // OneSignal App ID
  static const String _oneSignalAppId = 'a0aa2c71-2fc2-4869-8b56-df44a690e0f6';

  // Flag to track initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Global key for showing snackbars from anywhere
  GlobalKey<NavigatorState>? _navigatorKey;

  // WebView controller reference for navigation
  WebViewController? _webViewController;

  // Callback function for custom navigation from WebViewScreen
  Function(String url)? _navigationCallback;

  // Store pending notification URL for cold start
  String? _pendingNotificationUrl;

  /// Set the WebViewController for handling notification navigation
  /// Call this from your WebViewScreen after initializing the controller
  void setWebViewController(WebViewController controller, {Function(String url)? onNavigate}) {
    _webViewController = controller;
    _navigationCallback = onNavigate;
    developer.log(
      'WebViewController set for notifications',
      name: 'NotificationService',
    );

    // FIX: Don't automatically navigate here
    // The WebViewScreen will check for pending URL and handle it in _loadWebsite()
    // This prevents double-loading and race conditions
    if (_pendingNotificationUrl != null) {
      developer.log(
        '❄️ Pending URL will be handled by WebViewScreen: $_pendingNotificationUrl',
        name: 'NotificationService',
      );
      // Note: We don't clear or navigate here - WebViewScreen will pick it up
    }
  }

  /// Clear the pending notification URL after it has been used
  /// Call this from WebViewScreen after successfully loading the URL
  void clearPendingNotificationUrl() {
    if (_pendingNotificationUrl != null) {
      developer.log(
        '✅ Clearing pending notification URL: $_pendingNotificationUrl',
        name: 'NotificationService',
      );
      _pendingNotificationUrl = null;
    }
  }

  /// Initialize OneSignal with error handling
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) {
      developer.log(
        'OneSignal already initialized',
        name: 'NotificationService',
      );
      return;
    }

    try {
      developer.log('Initializing OneSignal...', name: 'NotificationService');

      // Store navigator key for showing snackbars
      _navigatorKey = navigatorKey;

      // Initialize OneSignal
      OneSignal.initialize(_oneSignalAppId);

      // Configure OneSignal for heads-up notifications (Android)
      // This ensures notifications appear as pop-ups like WhatsApp
      OneSignal.Notifications.clearAll(); // Clear any old notifications

      // Set up notification event handlers BEFORE requesting permission
      _setupNotificationHandlers();

      developer.log(
        'OneSignal initialized successfully with heads-up notification support',
        name: 'NotificationService',
      );
      _isInitialized = true;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize OneSignal',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Request notification permission from user
  Future<bool> requestPermission() async {
    try {
      developer.log(
        'Requesting notification permission...',
        name: 'NotificationService',
      );

      final accepted = await OneSignal.Notifications.requestPermission(true);

      developer.log(
        'Notification permission: ${accepted ? "GRANTED" : "DENIED"}',
        name: 'NotificationService',
      );

      return accepted;
    } catch (e, stackTrace) {
      developer.log(
        'Error requesting notification permission',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Set up notification event handlers
  void _setupNotificationHandlers() {
    developer.log(
      'Setting up notification handlers...',
      name: 'NotificationService',
    );

    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _handleNotificationReceived(event);
    });

    // Handle notification clicked/opened
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationClicked(event);
    });

    developer.log(
      'Notification handlers set up successfully',
      name: 'NotificationService',
    );
  }

  /// Helper to convert custom schemes to HTTPS
  String _normalizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Handle custom scheme: gameofcreators://auth/callback -> https://www.gameofcreators.com/auth/callback
      if (uri.scheme == 'gameofcreators') {
        if (uri.host == 'auth' && uri.path.contains('/callback')) {
          final httpsUrl = 'https://www.gameofcreators.com/auth/callback?${uri.query}';
          developer.log('🔄 Converted Auth Scheme: $url -> $httpsUrl', name: 'NotificationService');
          return httpsUrl;
        }
        
        if (uri.host == 'instagram' && uri.path.contains('/callback')) {
          final httpsUrl = 'https://www.gameofcreators.com/api/instagram/callback?${uri.query}';
          developer.log('🔄 Converted Instagram Scheme: $url -> $httpsUrl', name: 'NotificationService');
          return httpsUrl;
        }

        if (uri.host == 'youtube' && uri.path.contains('/callback')) {
          final httpsUrl = 'https://www.gameofcreators.com/api/youtube/callback?${uri.query}';
          developer.log('🔄 Converted YouTube Scheme: $url -> $httpsUrl', name: 'NotificationService');
          return httpsUrl;
        }
      }
      
      return url;
    } catch (e) {
      developer.log('Error normalizing URL: $url', error: e, name: 'NotificationService');
      return url;
    }
  }

  /// Navigate to a URL in the webview
  Future<void> navigateToUrl(String rawUrl) async {
    try {
      // 1. Normalize the URL (handle custom schemes)
      final url = _normalizeUrl(rawUrl);
      
      developer.log('Navigating webview to: $url', name: 'NotificationService');

      // Parse the URL to ensure it's valid
      final uri = Uri.tryParse(url);
      if (uri == null) {
        developer.log('Invalid URL: $url', name: 'NotificationService');
        return;
      }

      // Use custom callback if available (preferred - bypasses navigation delegate)
      if (_navigationCallback != null) {
        developer.log('Using navigation callback', name: 'NotificationService');
        _navigationCallback!(url);
        return;
      }

      // Fallback to direct webview loading
      if (_webViewController != null) {
        developer.log('Using direct webview loading', name: 'NotificationService');
        await _webViewController!.loadRequest(uri);
      } else {
        // WebView not ready yet - store URL for cold start
        developer.log(
          'WebViewController not set - storing URL for cold start: $url',
          name: 'NotificationService',
        );
        _pendingNotificationUrl = url;
        return;
      }

      developer.log(
        'Successfully navigated to: $url',
        name: 'NotificationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error navigating to URL',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get pending notification URL (for cold start)
  /// Call this from SplashScreen to retrieve the URL stored before WebView was ready
  ///
  /// IMPORTANT: This does NOT clear the pending URL!
  /// The URL will be cleared only when WebView controller uses it via setWebViewController()
  String? getPendingNotificationUrl() {
    final url = _pendingNotificationUrl;
    if (url != null) {
      developer.log(
        'Retrieved pending notification URL: $url',
        name: 'NotificationService',
      );
      // DO NOT clear here - let setWebViewController handle it when WebView is ready
    }
    return url;
  }

  /// Handle notification received while app is in foreground
  void _handleNotificationReceived(OSNotificationWillDisplayEvent event) {
    try {
      final notification = event.notification;

      developer.log(
        '📬 NOTIFICATION RECEIVED (Foreground)',
        name: 'NotificationService',
      );
      developer.log(
        'Title: ${notification.title}',
        name: 'NotificationService',
      );
      developer.log('Body: ${notification.body}', name: 'NotificationService');
      developer.log(
        'Additional Data: ${notification.additionalData}',
        name: 'NotificationService',
      );

      // Create our app notification model
      final appNotification = AppNotification(
        notificationId: notification.notificationId ?? '',
        title: notification.title ?? 'No Title',
        body: notification.body ?? 'No Body',
        additionalData: notification.additionalData ?? {},
        receivedAt: DateTime.now(),
      );

      developer.log(
        'Parsed Notification: $appNotification',
        name: 'NotificationService',
      );

      // Show a snackbar to user (if navigator key is available)
      _showNotificationSnackbar(
        title: appNotification.title,
        body: appNotification.body,
      );

      // Allow the notification to be displayed
      event.notification.display();
    } catch (e, stackTrace) {
      developer.log(
        'Error handling received notification',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle notification clicked/opened by user
  void _handleNotificationClicked(OSNotificationClickEvent event) {
    try {
      final notification = event.notification;

      developer.log('🔔 NOTIFICATION CLICKED', name: 'NotificationService');
      developer.log(
        'Title: ${notification.title}',
        name: 'NotificationService',
      );
      developer.log('Body: ${notification.body}', name: 'NotificationService');
      developer.log(
        'Additional Data: ${notification.additionalData}',
        name: 'NotificationService',
      );

      // Create our app notification model
      final appNotification = AppNotification(
        notificationId: notification.notificationId ?? '',
        title: notification.title ?? 'No Title',
        body: notification.body ?? 'No Body',
        additionalData: notification.additionalData ?? {},
        receivedAt: DateTime.now(),
      );

      developer.log(
        'Notification Clicked - Full Details: $appNotification',
        name: 'NotificationService',
      );

      // Parse additional data for navigation
      final additionalData = appNotification.additionalData;
      if (additionalData.isNotEmpty) {
        developer.log(
          'Processing notification data...',
          name: 'NotificationService',
        );

        // Check for specific data keys
        if (additionalData.containsKey('type')) {
          final notificationType = additionalData['type'];
          developer.log(
            'Notification type: $notificationType',
            name: 'NotificationService',
          );
        }

        // Handle URL navigation when notification is clicked
        // Support both 'url' and 'target_url' keys for flexibility
        final urlKey = additionalData.containsKey('url')
            ? 'url'
            : additionalData.containsKey('target_url')
                ? 'target_url'
                : null;

        if (urlKey != null) {
          final url = additionalData[urlKey] as String;
          developer.log(
            'Notification contains URL ($urlKey): $url',
            name: 'NotificationService',
          );

          // Navigate to the URL in webview
          navigateToUrl(url);

          // Show feedback to user
          if (_navigatorKey?.currentContext != null) {
            final context = _navigatorKey!.currentContext!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening: ${appNotification.title}'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // No additional data - just log that notification was clicked
        developer.log(
          'Notification clicked but no URL provided',
          name: 'NotificationService',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error handling notification click',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Show a snackbar when notification is received in foreground
  void _showNotificationSnackbar({
    required String title,
    required String body,
  }) {
    if (_navigatorKey?.currentContext != null) {
      final context = _navigatorKey!.currentContext!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 12)),
            ],
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Set user ID for OneSignal (call after successful login)
  /// This allows you to send notifications to specific users
  Future<void> setUserId(String userId) async {
    try {
      developer.log(
        'Setting OneSignal user ID: $userId',
        name: 'NotificationService',
      );

      await OneSignal.login(userId);

      developer.log('User ID set successfully', name: 'NotificationService');
    } catch (e, stackTrace) {
      developer.log(
        'Error setting user ID',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Logout user from OneSignal (call when user logs out)
  /// This stops associating the device with the user
  Future<void> logoutUser() async {
    try {
      developer.log(
        'Logging out OneSignal user...',
        name: 'NotificationService',
      );

      await OneSignal.logout();

      developer.log(
        'User logged out successfully',
        name: 'NotificationService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error logging out user',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get the current OneSignal player/device ID
  /// Useful for debugging and testing
  Future<String?> getDeviceId() async {
    try {
      final deviceState = OneSignal.User.pushSubscription.id;
      developer.log('Device ID: $deviceState', name: 'NotificationService');
      return deviceState;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting device ID',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Check if user has granted notification permission
  Future<bool> hasPermission() async {
    try {
      final permission = await OneSignal.Notifications.permission;
      return permission;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking notification permission',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get current notification permission status
  Future<void> logPermissionStatus() async {
    try {
      final hasPermission = await this.hasPermission();
      final deviceId = await getDeviceId();

      developer.log('=== NOTIFICATION STATUS ===', name: 'NotificationService');
      developer.log(
        'Permission Granted: $hasPermission',
        name: 'NotificationService',
      );
      developer.log(
        'Device ID: ${deviceId ?? "Not available"}',
        name: 'NotificationService',
      );
      developer.log('==========================', name: 'NotificationService');
    } catch (e, stackTrace) {
      developer.log(
        'Error logging permission status',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/*
===============================================================================
USAGE EXAMPLES:
===============================================================================

1. INITIALIZE IN main.dart:
-------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();

  // Initialize other services
  await AuthService.initializeSupabase();

  // Initialize notifications
  await NotificationService().initialize(navigatorKey: navigatorKey);

  // Request permission (or do this later in app)
  await NotificationService().requestPermission();

  runApp(MyApp(navigatorKey: navigatorKey));
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({required this.navigatorKey, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: SplashScreen(),
    );
  }
}

2. SET WEBVIEW CONTROLLER IN WebViewScreen:
-------------------------------
@override
void initState() {
  super.initState();
  _initializeWebView();
}

void _initializeWebView() {
  // ... create webview controller ...

  // IMPORTANT: Set the controller in NotificationService for navigation
  // Provide a callback that sets a flag to bypass navigation delegate checks
  NotificationService().setWebViewController(
    _webViewController,
    onNavigate: (String url) {
      _pendingNotificationUrl = url; // Flag to allow this URL
      _webViewController.loadRequest(Uri.parse(url));
    },
  );
}

// In your navigation delegate:
onNavigationRequest: (NavigationRequest request) async {
  // Allow notification URLs to bypass external link checks
  if (_pendingNotificationUrl != null && request.url == _pendingNotificationUrl) {
    _pendingNotificationUrl = null;
    return NavigationDecision.navigate;
  }
  // ... rest of your navigation logic ...
}

3. SET USER ID AFTER LOGIN:
-------------------------------
// After successful login
final userId = userResponse.id; // or email, or any unique identifier
await NotificationService().setUserId(userId);

4. LOGOUT USER:
-------------------------------
// When user logs out
await NotificationService().logoutUser();

5. CHECK PERMISSION STATUS:
-------------------------------
final hasPermission = await NotificationService().hasPermission();
if (!hasPermission) {
  // Show UI to request permission
  await NotificationService().requestPermission();
}

6. GET DEVICE ID FOR TESTING:
-------------------------------
final deviceId = await NotificationService().getDeviceId();
print('Send test notification to: $deviceId');

7. LOG NOTIFICATION STATUS:
-------------------------------
await NotificationService().logPermissionStatus();

===============================================================================
TESTING NOTIFICATIONS WITH WEBVIEW NAVIGATION:
===============================================================================

1. Get device ID from logs or using getDeviceId()
2. Go to OneSignal dashboard → Messages → New Push
3. Create a new notification with:
   - Title: "New Message"
   - Body: "You have a new message waiting"
   - Additional Data (JSON):
     {
       "url": "https://www.gameofcreators.com/dashboard/messages",
       "type": "message"
     }
4. Under "Send to" select "Player IDs" and paste your device ID
5. Send the notification
6. When you click the notification, it will:
   - Log the click event
   - Navigate to the URL in your webview
   - Show a snackbar confirming navigation

HEADS-UP NOTIFICATION TIPS (Android):
-------------------------------
For notifications to appear as pop-ups (like WhatsApp):

1. On OneSignal Dashboard:
   - Set "Priority" to HIGH when creating notification
   - Set "Android Channel ID" to your channel (OneSignal creates default)

2. On Device Settings:
   - Go to Settings → Apps → Your App → Notifications
   - Ensure notifications are enabled
   - Set importance to "High" or "Urgent"
   - Enable "Pop on screen" or "Heads-up notifications"

3. Testing Priority in OneSignal:
   - In dashboard, under "Delivery" tab
   - Set "Priority" to "High"
   - This makes notifications more likely to show as heads-up

Note: Android 12+ requires notification permission at runtime (already handled)

NOTIFICATION DATA FORMAT:
-------------------------------
Send notifications with this JSON structure in Additional Data:
{
  "url": "https://www.gameofcreators.com/your-page",
  // OR
  "target_url": "https://www.gameofcreators.com/your-page",
  // Both 'url' and 'target_url' are supported

  "type": "custom_type",
  "itemId": "123",
  "anyCustomField": "value"
}

The app will:
- Parse the URL (supports both 'url' and 'target_url' keys)
- Navigate to it in webview
- Log all additional data for debugging
- Show user feedback when navigating

===============================================================================
*/
