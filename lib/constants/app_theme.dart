import 'package:flutter/material.dart';

// Define color constants
class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color secondaryGreen = Color(0xFF2E7D32);
  static const Color lightText = Colors.white;
  static const Color darkText = Colors.black;
  static const Color subtleShadow = Colors.white70;
  static const Color fruitText = Color(0x99000000); // black.withAlpha(153)
}

// Define text style constants
class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 64,
    fontFamily: 'Pacifico',
    fontWeight: FontWeight.w900,
    color: AppColors.primaryGreen,
    letterSpacing: 2,
    shadows: [
      Shadow(
        offset: Offset(2, 2),
        blurRadius: 3.0,
        color: AppColors.subtleShadow,
      ),
    ],
  );

  static const TextStyle slogan = TextStyle(
    fontSize: 18,
    fontFamily: 'Quicksand',
    fontWeight: FontWeight.w800,
    color: AppColors.secondaryGreen,
    letterSpacing: 1,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2.0,
        color: AppColors.subtleShadow,
      ),
    ],
  );

  static const TextStyle googleButton = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold,
    color: AppColors.darkText, // Ensure foreground color is set in ButtonStyle
  );

  static const TextStyle welcomeMessage = TextStyle(
    fontSize: 28, 
    fontWeight: FontWeight.bold
  );
}

// Define the main theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: AppColors.lightText,
      fontFamily: 'Quicksand', // Default font
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.lightText, // Title and icons color
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightText,
          foregroundColor: AppColors.darkText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.googleButton,
          elevation: 2,
        ),
      ),
      textTheme: const TextTheme(
        // You can define more specific text themes here if needed
        headlineLarge: AppTextStyles.title, 
        bodyLarge: AppTextStyles.slogan,
        headlineMedium: AppTextStyles.welcomeMessage,
      ),
    );
  }
}

// Constants for asset paths
class AppAssets {
  static const String googleLogo = 'assets/google_logo.png';
  static const String blueberry = 'assets/fruits/blueberry.png';
  static const String strawberry = 'assets/fruits/strawberry.png';
  static const String broccoli = 'assets/fruits/broccoli.png';
  static const String carrot = 'assets/fruits/carrot.png';
  static const String cucumber = 'assets/fruits/cucumber.png';
  static const String tomato = 'assets/fruits/tomato.png';
} 