import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:harvest/core/constants/app_constants.dart';
import 'package:harvest/core/services/user_preferences_service.dart';
import 'package:harvest/features/auth/screens/auth_gate_screen.dart';
import 'package:harvest/features/auth/screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'features/donor/screens/donor_dashboard_screen.dart';
import 'package:harvest/features/recipient/screens/recipient_dashboard_screen.dart';
import 'package:harvest/features/donor/screens/post_donation_screen.dart';
import 'package:harvest/features/donor/screens/donation_tracking_screen.dart';
import 'package:harvest/features/recipient/screens/requests_screen.dart';
import 'package:harvest/features/auth/screens/role_selection_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'package:harvest/features/donor/screens/map_view_screen.dart';

import 'package:harvest/core/theme/app_theme.dart';

// Remove or comment out this line if firebase_options.dart doesn't exist:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  // Initialize local persistent cache for user role and session
  await UserPreferencesService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HarvestHub',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGateScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(), // Remove 'const' here
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/donor-dashboard': (context) => const DonorDashboardScreen(),
        '/recipient-dashboard': (context) => const RecipientDashboardScreen(),
        '/post-donation': (context) => const PostDonationScreen(),
        '/donation-tracking': (context) => const DonationTrackingScreen(),
        '/requests': (context) => const RequestsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/map-view': (context) => const MapViewScreen(),
      },
      onUnknownRoute: (settings) {
        debugPrint('⚠️ Unknown route requested: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Route not found: ${settings.name}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    ),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
