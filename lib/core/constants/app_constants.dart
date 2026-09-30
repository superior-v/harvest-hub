import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── APP COLORS (CENTRALIZED DESIGN SYSTEM TOKENS) ───────────────────────────

class AppColors {
  // Primary Forest & Leaf (Donor Identity & Eco Brand)
  static const Color forest = Color(0xFF1A3A1F); // Deep forest green
  static const Color leaf = Color(0xFF3D7A45); // Mid vibrant leaf
  static const Color sprout = Color(0xFF6BBF6A); // Fresh sprout green
  static const Color primaryGreen = Color(0xFF2F7D4D); // Standard primary brand green
  static const Color deepGreen = Color(0xFF1F5A38); // Deep brand green
  static const Color lightGreen = Color(0xFFE6F1E8); // Light green tint
  static const Color dew = Color(0xFFE8F4EA); // Lightest ecological tint

  // Ocean & Sea Foam (Recipient Identity & Proximity)
  static const Color deepOcean = Color(0xFF0F3D4C); // Deep navy ocean
  static const Color wave = Color(0xFF1A6B8A); // Ocean wave blue
  static const Color foam = Color(0xFF2E9E8E); // Sea foam cyan
  static const Color foamPale = Color(0xFFE4F2F8); // Very light cyan/blue tint
  static const Color sky = Color(0xFF4A90C4); // Sky blue accent

  // Earth & Warm Clay (Farmer / Harvest Identity & Highlights)
  static const Color clay = Color(0xFFD4956A); // Warm clay amber
  static const Color earth = Color(0xFF8A5A3C); // Rich terracotta earth
  static const Color clayPale = Color(0xFFFAF2EB); // Light clay tint

  // Role Identity Shortcuts
  static const Color roleDonor = primaryGreen;
  static const Color roleRecipient = wave;
  static const Color roleFarmer = clay;

  // Secondary legacy aliases
  static const Color orange = earth;
  static const Color blue = sky;
  static const Color purple = Color(0xFF6D7E73);

  // Neutrals & Surfaces
  static const Color ink = Color(0xFF0F1F12); // High-contrast primary dark text
  static const Color darkGray = Color(0xFF1E293B); // Dark slate neutral
  static const Color slate = Color(0xFF5A7080); // Mid slate body text
  static const Color mediumGray = Color(0xFF64748B); // Secondary muted text
  static const Color lightGray = Color(0xFFD8EAF2); // Neutral border
  static const Color border = Color(0xFFD8EAF2); // Subtle border divider
  static const Color divider = Color(0xFFDEEADE); // Green-tinted divider
  static const Color mist = Color(0xFFF2F7FA); // Clean cool background
  static const Color background = Color(0xFFF8FAFC); // Main canvas background
  static const Color surface = Color(0xFFFFFFFF); // Card & modal background
  static const Color white = Color(0xFFFFFFFF);

  // Status & Feedback Colors
  static const Color success = Color(0xFF2F7D4D);
  static const Color warning = Color(0xFFE67E22);
  static const Color error = Color(0xFFD63B2F);
  static const Color info = Color(0xFF1A6B8A);

  // ── Centralized Gradients ──────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, deepGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroForestGradient = LinearGradient(
    colors: [forest, deepGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroOceanGradient = LinearGradient(
    colors: [deepOcean, wave],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sproutGradient = LinearGradient(
    colors: [leaf, sprout],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foamGradient = LinearGradient(
    colors: [wave, foam],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient clayGradient = LinearGradient(
    colors: [earth, clay],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [dew, white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Centralized Shadows ────────────────────────────────────────────────────
  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double alpha = 0.3}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

// ─── APP TYPOGRAPHY (OUTFIT FOR HEADERS + INTER FOR DATA/BODY) ───────────────

class AppTextStyles {
  // Headings — Powered by Google Fonts Outfit
  static TextStyle get heading1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.6,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.4,
        height: 1.25,
      );

  static TextStyle get heading3 => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
      );

  static TextStyle get heading4 => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  // Body & Data Tables — Powered by Google Fonts Inter
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.slate,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.slate,
      );

  // Caption & Metadata Labels
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: AppColors.slate,
      );

  static TextStyle get captionBold => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.slate,
        letterSpacing: 0.2,
      );

  // Data / Metric Numbers
  static TextStyle get metricValue => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: -0.5,
      );

  static TextStyle get dataTableLabel => GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.slate,
      );

  static TextStyle get dataTableValue => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  // Buttons
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );
}

// ─── APP DIMENSIONS (CENTRALIZED RADII & SPACING) ────────────────────────────

class AppDimensions {
  // Padding & Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  // Border Radius Tokens
  static const double radiusXS = 6.0;
  static const double radiusS = 10.0;
  static const double radiusM = 14.0;
  static const double radiusL = 18.0;
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

// ─── APP STRINGS & ICONS ─────────────────────────────────────────────────────

class AppStrings {
  static const String appName = 'HarvestHub';
  static const String appTagline = 'Share. Connect. Sustain.';

  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account?";
  static const String alreadyHaveAccount = 'Already have an account?';

  static const String donor = 'Donor';
  static const String recipient = 'Recipient';
  static const String farmer = 'Farmer';
  static const String admin = 'Admin';

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

  static const String food = 'Food';
  static const String clothes = 'Clothes';
  static const String electronics = 'Electronics';
  static const String books = 'Books';
  static const String furniture = 'Furniture';
  static const String other = 'Other';

  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
}

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

class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 600);
}
