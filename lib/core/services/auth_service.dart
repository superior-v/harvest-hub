import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harvest/core/services/user_preferences_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔵 Attempting login with email: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Login successful! User: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error Code: ${e.code}');
      debugPrint('❌ Firebase Auth Error Message: ${e.message}');
      throw _getErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('🔵 Attempting signup with email: $email');

      // Create user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User created: ${credential.user?.uid}');

      // Update display name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.reload();
        debugPrint('✅ Display name updated to: $name');
      }

      debugPrint('✅ Signup successful!');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error Code: ${e.code}');
      debugPrint('❌ Firebase Auth Error Message: ${e.message}');
      throw _getErrorMessage(e.code);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('🔵 Attempting logout');
      await UserPreferencesService.clearUserData();
      await _auth.signOut();
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      throw 'Failed to sign out';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      throw _getErrorMessage(e.code);
    }
  }

  String _getErrorMessage(String code) {
    switch (code.toLowerCase()) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase Authentication.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'channel-error':
        return 'Please enter both email and password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
