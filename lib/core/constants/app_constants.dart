import 'package:flutter/material.dart';

// App Colors
class AppColors {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF2F7D4D);
  static const Color deepGreen = Color(0xFF1F5A38);
  static const Color lightGreen = Color(0xFFE6F1E8);

  // Role Identity Colors
  static const Color roleDonor = Color(0xFF2F7D4D);
  static const Color roleRecipient = Color(0xFF4E9FD1);
  static const Color roleFarmer = Color(0xFF8A5A3C);

  // Secondary Colors
  static const Color orange = Color(0xFF8A5A3C);
  static const Color blue = Color(0xFF4E9FD1);
  static const Color purple = Color(0xFF6D7E73);

  // Neutral Colors
  static const Color darkGray = Color(0xFF28332C);
  static const Color mediumGray = Color(0xFF5B6A61);
  static const Color lightGray = Color(0xFFD7DED8);
  static const Color background = Color(0xFFFAF6F0);
  static const Color white = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF2F7D4D);
  static const Color warning = Color(0xFFB26A3D);
  static const Color error = Color(0xFFC2473E);
  static const Color info = Color(0xFF3E7E93);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primaryGreen,
      deepGreen
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      lightGreen,
      white
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// App Text Styles
class AppTextStyles {
  static const String fontFamily = 'DMSans';

  // Headings
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.darkGray,
    fontFamily: fontFamily,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    fontFamily: fontFamily,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkGray,
    fontFamily: fontFamily,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    fontFamily: fontFamily,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGray,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGray,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGray,
    fontFamily: fontFamily,
  );

  // Caption & Labels
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGray,
    fontFamily: fontFamily,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mediumGray,
    fontFamily: fontFamily,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamily,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamily,
  );
}

// App Dimensions
class AppDimensions {
  // Padding
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 999.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  // Card Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
}

// App Strings
class AppStrings {
  // App Info
  static const String appName = 'HarvestHub';
  static const String appTagline = 'Share. Connect. Sustain.';

  // Auth
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';

  // User Roles
  static const String donor = 'Donor';
  static const String recipient = 'Recipient';
  static const String farmer = 'Farmer';
  static const String admin = 'Admin';

  // Common
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String submit = 'Submit';
  static const String loading = 'Loading...';
  static const String noData = 'No data available';
  static const String error = 'Error';
  static const String success = 'Success';

  // Donation Categories
  static const String food = 'Food';
  static const String clothes = 'Clothes';
  static const String electronics = 'Electronics';
  static const String books = 'Books';
  static const String furniture = 'Furniture';
  static const String other = 'Other';

  // Status
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
}

// App Icons (You can use custom icons or Material Icons)
class AppIcons {
  static const IconData home = Icons.home_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData add = Icons.add_circle_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData message = Icons.message_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData analytics = Icons.analytics_rounded;
  static const IconData verified = Icons.verified_rounded;
  static const IconData star = Icons.star_rounded;
  static const IconData favorite = Icons.favorite_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData category = Icons.category_rounded;
  static const IconData info = Icons.info_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_rounded;
  static const IconData success = Icons.check_circle_rounded;
}

// App Animation Durations
class AppDurations {
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
}
