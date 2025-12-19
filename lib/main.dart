import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'screens/splash_screen.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create global navigator key for notifications
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // 1. Initialize Services
  await AuthService.initializeSupabase();
  await NotificationService().initialize(navigatorKey: navigatorKey);
  await NotificationService().requestPermission();

  // 2. Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. --- COLD START & DEEP LINK FIX ---
  // We catch the link HERE, before the UI loads.
  final appLinks = AppLinks();
  bool coldStartLinkHandled = false;

  // A. Handle Cold Start (App was closed)
  try {
    final Uri? initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint("🚀 Main.dart caught Cold Start Link: $initialUri");
      // Store it in NotificationService immediately.
      // The Service will hold it until the WebView is ready.
      NotificationService().navigateToUrl(initialUri.toString());
      coldStartLinkHandled = true;
    }
  } catch (e) {
    debugPrint("Error checking initial link: $e");
  }


  bool skipFirstEvent = coldStartLinkHandled;

  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      // Skip first stream event if it's the same as cold start link
      if (skipFirstEvent) {
        debugPrint("⏭️ Skipping duplicate cold start link from stream: $uri");
        skipFirstEvent = false;
        return;
      }

      debugPrint("🔗 Main.dart caught Background Link: $uri");
      NotificationService().navigateToUrl(uri.toString());
    }
  });
  // -------------------------------------

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
