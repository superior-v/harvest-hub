import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching and managing user session and role locally.
class UserPreferencesService {
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences during app startup in main().
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ UserPreferencesService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing UserPreferencesService: $e');
    }
  }

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save the user's active role ('donor', 'recipient', 'farmer').
  static Future<bool> saveUserRole(String role) async {
    final prefs = await _instance;
    final normalized = role.toLowerCase().trim();
    debugPrint('💾 Cached user role locally: $normalized');
    return await prefs.setString(_keyUserRole, normalized);
  }

  /// Get the cached role synchronously (available if init() ran at startup).
  static String? getUserRoleSync() {
    return _prefs?.getString(_keyUserRole);
  }

  /// Get the cached role asynchronously.
  static Future<String?> getUserRole() async {
    final prefs = await _instance;
    return prefs.getString(_keyUserRole);
  }

  /// Save full user session info locally.
  static Future<void> saveUserSession({
    required String uid,
    String? email,
    String? name,
    String? role,
  }) async {
    final prefs = await _instance;
    await prefs.setString(_keyUserId, uid);
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_keyUserEmail, email);
    }
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_keyUserName, name);
    }
    if (role != null && role.isNotEmpty) {
      final normalized = role.toLowerCase().trim();
      await prefs.setString(_keyUserRole, normalized);
    }
    debugPrint('💾 Saved user session locally for uid: $uid');
  }

  /// Clear all cached user data (called during logout).
  static Future<void> clearUserData() async {
    final prefs = await _instance;
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    debugPrint('🧹 Cleared local user preferences and cached role');
  }

  /// Resolve the dashboard route for a given role.
  static String getDashboardRouteForRole(String? role) {
    if (role == null || role.isEmpty) {
      return '/role-selection';
    }

    switch (role.toLowerCase().trim()) {
      case 'donor':
        return '/donor-dashboard';
      case 'recipient':
      case 'farmer':
        return '/recipient-dashboard';
      default:
        return '/role-selection';
    }
  }
}
