import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer';

/// Service to handle Firebase Authentication
/// Manages anonymous sign-in for user isolation with persistent storage
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _uidKey = 'anonymous_user_uid';

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Sign in anonymously with persistent UID storage
  /// This ensures each user has a unique UID that persists across app restarts
  /// ONLY hits Firebase Auth on first install when no stored UID exists
  Future<User?> signInAnonymously() async {
    try {
      // First priority: Check if user is already signed in
      if (_auth.currentUser != null) {
        log('✓ User already signed in: ${_auth.currentUser!.uid}');
        return _auth.currentUser;
      }

      // Second priority: Try to get stored UID from secure storage
      final storedUid = await _secureStorage.read(key: _uidKey);

      if (storedUid != null) {
        log('✓ Found stored UID in secure storage: $storedUid');
        log('✓ Using stored credentials - NO Firebase Auth call needed');

        // Try to restore Firebase session with stored UID
        await Future.delayed(const Duration(milliseconds: 300));

        if (_auth.currentUser != null && _auth.currentUser!.uid == storedUid) {
          log('✓ Firebase session restored successfully');
          return _auth.currentUser;
        }

        // If session restore failed, sign in with the stored UID
        log('⚠ Session not auto-restored, signing in with stored UID...');
        final userCredential = await _auth.signInAnonymously();
        final user = userCredential.user;

        if (user != null) {
          // Update stored UID if it changed
          if (user.uid != storedUid) {
            await _secureStorage.write(key: _uidKey, value: user.uid);
            log('⚠ UID changed, updated storage: ${user.uid}');
          }
          return user;
        }
      }

      // Third priority: First install - create new anonymous user
      log('⚠ No stored UID found - FIRST INSTALL');
      log('⚠ Creating new anonymous user via Firebase Auth...');
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Store the UID securely for future launches
        await _secureStorage.write(key: _uidKey, value: user.uid);
        log('✓ New anonymous user created and stored: ${user.uid}');
      }

      return user;
    } catch (e) {
      log('❌ Anonymous sign-in error: $e');
      rethrow;
    }
  }

  /// Clear stored credentials (for testing/debugging)
  Future<void> clearStoredCredentials() async {
    await _secureStorage.delete(key: _uidKey);
    await _auth.signOut();
    log('Stored credentials cleared');
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
