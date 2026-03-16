import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:harvest/core/constants/app_constants.dart';
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

// Remove or comment out this line if firebase_options.dart doesn't exist:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Use this instead of DefaultFirebaseOptions:
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HarvestHub',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.dmSansTextTheme(
          ThemeData.light().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(
            fontSize: 42,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
          displayMedium: GoogleFonts.dmSerifDisplay(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          primary: AppColors.primaryGreen,
          secondary: AppColors.orange,
          surface: Colors.white,
          error: AppColors.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.deepGreen,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 1.4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.deepGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentTextStyle: const TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/login',
      routes: {
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
