import 'package:flutter/material.dart';

/// RecallMe Warm Theme - Richer, more vibrant version
/// Still dementia-friendly but with more visual depth
class AppColors {
  AppColors._();

  // Primary Colors - Deeper, richer warm tones
  static const Color primaryYellow = Color(0xFFE8D4A0); // Darker cream
  static const Color primaryOrange = Color(0xFFE8943B); // Richer orange
  static const Color primaryCoral = Color(0xFFE25F4E); // Deeper coral

  // Legacy mappings for compatibility
  static const Color primaryBlue = Color(0xFFE8943B); // Maps to rich orange
  static const Color primaryDark = Color(0xFFCC7A28);
  static const Color primaryLight = Color(0xFFF5B066);

  // Accent Colors - More saturated
  static const Color accentOrange = Color(0xFFE8943B);
  static const Color accentCoral = Color(0xFFE25F4E);
  static const Color accentPeach = Color(0xFFFFCA99);
  static const Color accentBlue = Color(0xFFF5B066); // Maps to golden
  static const Color accentLight = Color(0xFFFFF0DB);
  static const Color accentPurple = Color(0xFFB88A5D); // Rich brown
  static const Color accentTeal = Color(0xFF6BA368); // Richer sage green

  // Legacy Mappings
  static const Color secondaryGreen = Color(0xFF6BA368);
  static const Color accentYellow = Color(0xFFE8B939); // Rich gold
  static const Color background = Color(0xFFF5EDE0);
  static const Color info = accentOrange;

  // Background Colors - Slightly darker cream
  static const Color backgroundTop = Color(0xFFFFF0DB);
  static const Color backgroundBottom = Color(0xFFF5EDE0);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color lightSand = Color(0xFFEADDC7);

  // Text Colors - Deeper brown for better contrast
  static const Color textPrimary = Color(0xFF3D2E1F);
  static const Color textSecondary = Color(0xFF5C4A3A);
  static const Color textLight = Color(0xFF8C7B6A);

  // Status Colors - More vibrant
  static const Color success = Color(0xFF4CAF50); // Brighter green
  static const Color warning = Color(0xFFE8943B);
  static const Color error = Color(0xFFE25F4E);
  static const Color missed = Color(0xFFB0B0B0); // Grey for missed tasks

  // Gradients - Richer, more depth
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

  static const LinearGradient calmGradient = mainGradient;

  static const LinearGradient bluePillGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8943B), Color(0xFFF5B066)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8943B), Color(0xFFF5B066)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB88A5D), Color(0xFFD4A574)],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6BA368), Color(0xFF8BC88A)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE25F4E), Color(0xFFFF8A7A)],
  );

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8D4A0), Color(0xFFFFF0DB)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8943B), Color(0xFFE25F4E)],
  );

  static const LinearGradient missedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
  );

  // Shadows - Warmer, deeper
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF5C4A3A).withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF5C4A3A).withOpacity(0.10),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: const Color(0xFFE8943B).withOpacity(0.40),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Doodle Colors - Warmer
  static const Color doodleBody = Color(0xFFFFF5E6);
  static const Color doodleOutline = Color(0xFF5C4A3A);
  static const Color doodleBlush = Color(0xFFF5A8A0);
  static const Color doodleSparkle = Color(0xFFE8B939);
}
