import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create global navigator key for notifications
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Initialize Supabase
  await AuthService.initializeSupabase();

  // Initialize OneSignal with our notification service
  await NotificationService().initialize(navigatorKey: navigatorKey);

  // Request notification permission
  await NotificationService().requestPermission();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(GameOfCreatorsApp(navigatorKey: navigatorKey));
}

class GameOfCreatorsApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const GameOfCreatorsApp({required this.navigatorKey, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.backgroundColor,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppConstants.primaryColor,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
