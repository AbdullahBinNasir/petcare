import 'package:flutter/material.dart';

class PetCareTheme {
  // Enhanced color scheme with your specified colors
  static const Color primaryBeige = Color.fromARGB(255, 255, 255, 255);
  static const Color primaryBrown = Color(0xFF7D4D20); // Your brown color #7d4d20
  static const Color lightBrown = Color(0xFF9B6B3A); // Lighter shade of your brown
  static const Color darkBrown = Color(0xFF5A3417); // Darker shade for depth
  static const Color accentGold = Color(0xFFD4AF37); // Gold accent
  static const Color softGreen = Color(0xFF8FBC8F); // Soft green
  static const Color warmRed = Color(0xFFCD853F); // Warm red-brown
  static const Color warmPurple = Color(0xFFBC9A6A); // Warm taupe
  static const Color cardWhite = Color(0xFFFFFDF7); // Warm white for cards
  static const Color shadowColor = Color(0x1A7D4D20); // Subtle shadow
  
  // Text colors
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textLight = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  
  // Background colors
  static const Color cardBackground = Color(0xFFFFFDF7);
  static const Color surfaceBackground = Color(0xFFF8F6F0);
  
  // Gradients
  static const List<Color> primaryGradient = [
    primaryBrown,
    lightBrown,
  ];
  
  static const List<Color> accentGradient = [
    accentGold,
    lightBrown,
  ];
  
  // Background gradient
  static const List<Color> backgroundGradient = [
    Color(0xFFFFFDF7),
    Color(0xFFF8F6F0),
  ];
  
  // Shadows
  static const BoxShadow cardShadow = BoxShadow(
    color: shadowColor,
    blurRadius: 8,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );
  
  static const BoxShadow elevatedShadow = BoxShadow(
    color: shadowColor,
    blurRadius: 20,
    offset: Offset(0, 10),
    spreadRadius: 2,
  );
  
  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 20.0;
  static const double borderRadiusXXLarge = 24.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 40.0;
  
  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textDark,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textDark,
    letterSpacing: 0.3,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.4,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textLight,
    height: 1.3,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
    height: 1.2,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textMuted,
    letterSpacing: 0.2,
  );
}
