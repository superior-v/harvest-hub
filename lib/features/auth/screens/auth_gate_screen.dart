import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/user_preferences_service.dart';

/// Smart Route Guard & Animated Splash Auth Gate.
/// Displays the logo & brand animation on app launch,
/// while seamlessly resolving auth state and local cached role.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({Key? key}) : super(key: key);

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();

    // Start resolution and guarantee the splash is visible for ~1.8s
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSplashAndRoute();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startSplashAndRoute() async {
    // Run route resolution and minimum splash duration in parallel
    final results = await Future.wait([
      _resolveTargetRoute(),
      Future.delayed(const Duration(milliseconds: 1800)),
    ]);

    final targetRoute = results[0] as String;
    _navigateTo(targetRoute);
  }

  Future<String> _resolveTargetRoute() async {
    try {
      // 1. Check current Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return '/login';
      }

      // 2. Check locally cached role first (instant)
      final cachedRole = UserPreferencesService.getUserRoleSync() ??
          await UserPreferencesService.getUserRole().timeout(
            const Duration(milliseconds: 800),
            onTimeout: () => null,
          );

      if (cachedRole != null && cachedRole.isNotEmpty) {
        debugPrint('🚀 Fast-routing with cached role: $cachedRole');
        return UserPreferencesService.getDashboardRouteForRole(cachedRole);
      }

      // 3. Role is not in local cache -> fetch from Firestore with timeout
      debugPrint('🔍 Local role cache miss. Querying Firestore for uid: ${user.uid}');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 2));

      if (doc.exists) {
        final data = doc.data();
        final role = data?['role'] as String?;

        if (role != null && role.isNotEmpty) {
          await UserPreferencesService.saveUserRole(role);
          return UserPreferencesService.getDashboardRouteForRole(role);
        }
      }

      return '/role-selection';
    } catch (e) {
      debugPrint('❌ Error resolving user on launch: $e');
      return '/login';
    }
  }

  void _navigateTo(String route) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient gradient circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB26A3D).withOpacity(0.06),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand App Logo
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.28),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            child: const Icon(
                              Icons.eco_rounded,
                              size: 64,
                              color: AppColors.deepGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HarvestHub',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting donors, farmers & communities',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 42),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
