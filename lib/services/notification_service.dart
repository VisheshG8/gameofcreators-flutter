import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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

      // Set up notification event handlers BEFORE requesting permission
      _setupNotificationHandlers();

      developer.log(
        'OneSignal initialized successfully',
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

      // Parse additional data for navigation (example)
      final additionalData = appNotification.additionalData;
      if (additionalData.isNotEmpty) {
        developer.log(
          'Processing notification data...',
          name: 'NotificationService',
        );

        // Example: Check for specific data keys
        if (additionalData.containsKey('type')) {
          final notificationType = additionalData['type'];
          developer.log(
            'Notification type: $notificationType',
            name: 'NotificationService',
          );

          // TODO: Add navigation logic here based on notification type
        }

        if (additionalData.containsKey('url')) {
          final url = additionalData['url'];
          developer.log(
            'Notification contains URL: $url',
            name: 'NotificationService',
          );
          // TODO: Navigate to URL in webview
        }
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

2. SET USER ID AFTER LOGIN:
-------------------------------
// After successful login
final userId = userResponse.id; // or email, or any unique identifier
await NotificationService().setUserId(userId);

3. LOGOUT USER:
-------------------------------
// When user logs out
await NotificationService().logoutUser();

4. CHECK PERMISSION STATUS:
-------------------------------
final hasPermission = await NotificationService().hasPermission();
if (!hasPermission) {
  // Show UI to request permission
  await NotificationService().requestPermission();
}

5. GET DEVICE ID FOR TESTING:
-------------------------------
final deviceId = await NotificationService().getDeviceId();
print('Send test notification to: $deviceId');

6. LOG NOTIFICATION STATUS:
-------------------------------
await NotificationService().logPermissionStatus();

===============================================================================
TESTING NOTIFICATIONS:
===============================================================================

1. Get device ID from logs or using getDeviceId()
2. Go to OneSignal dashboard
3. Create a new notification
4. Under "Send to" select "Player IDs" and paste your device ID
5. Send the notification

To test with additional data (for navigation):
Send notification with Additional Data in JSON format:
{
  "type": "message",
  "url": "https://example.com/page",
  "itemId": "123"
}

===============================================================================
*/
