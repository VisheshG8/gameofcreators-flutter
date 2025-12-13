import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Service for handling native Google Sign-In and Supabase authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use Web Client ID (not Android/iOS client ID)
    serverClientId: AppConstants.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  /// Initialize Supabase
  static Future<void> initializeSupabase() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: false, // Set to true for debugging
    );
  }

  /// Perform native Google Sign-In and exchange for Supabase session
  /// Returns the session tokens (accessToken and refreshToken)
  Future<Session?> signInWithGoogle() async {
    try {
      // Step 1: Sign in with Google natively
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Step 2: Get authentication tokens from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('No ID Token found from Google Sign-In');
      }

      // Step 3: Exchange Google ID Token for Supabase Session
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.session == null) {
        throw Exception('Failed to create Supabase session');
      }

      return response.session;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Sign out from both Google and Supabase
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current Supabase session
  Session? getCurrentSession() {
    return Supabase.instance.client.auth.currentSession;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final session = getCurrentSession();
    return session != null && !session.isExpired;
  }
}

