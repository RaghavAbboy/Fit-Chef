// --- Purpose of this File ---
// This file centralizes the look and feel (theme) and asset paths for the app.
// Using constants here makes it easy to change colors, fonts, or image locations
// consistently across the entire application.

import 'package:flutter/material.dart';

// --- Color Definitions ---
// Defines all the specific colors used in the application.
// Using named constants (like `primaryGreen`) makes the code more readable
// than using raw color codes (like `Color(0xFF1B5E20)`) everywhere.
class AppColors {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color secondaryGreen = Color(0xFF2E7D32);
  static const Color lightText = Colors.white;
  static const Color darkText = Colors.black;
  static const Color subtleShadow = Colors.white70;
  static const Color fruitText = Color(0x99000000); // Represents black with 60% opacity
}

// --- Text Style Definitions ---
// Defines reusable text styles for different parts of the UI (titles, buttons, etc.).
// This ensures text looks consistent and makes it easy to update styles globally.
class AppTextStyles {
  // Style for the main app title ("Fit Chef") on the login screen.
  static const TextStyle title = TextStyle(
    fontSize: 64,
    fontFamily: 'Pacifico', // Custom font defined in pubspec.yaml
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

  // Style for the slogan text below the title on the login screen.
  static const TextStyle slogan = TextStyle(
    fontSize: 18,
    fontFamily: 'Quicksand', // Custom font defined in pubspec.yaml
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

  // Style specifically for the Google Sign-In button text.
  static const TextStyle googleButton = TextStyle(
    fontSize: 18, 
    fontWeight: FontWeight.bold,
    color: AppColors.darkText, // Actual text color is set via ButtonStyle foregroundColor
  );

  // Style for the welcome message on the home page.
  static const TextStyle welcomeMessage = TextStyle(
    fontSize: 28, 
    fontWeight: FontWeight.bold
  );
}

// --- Main Application Theme ---
// Defines the overall visual theme for the application using the colors
// and text styles defined above.
class AppTheme {
  // `lightTheme` provides the configuration for the app's appearance.
  static ThemeData get lightTheme {
    return ThemeData(
      // Sets the base color scheme (affects various widget colors).
      primarySwatch: Colors.green,
      // Sets the default background color for screens (`Scaffold` widgets).
      scaffoldBackgroundColor: AppColors.lightText,
      // Sets the default font family unless overridden by a specific TextStyle.
      fontFamily: 'Quicksand',
      // Configures the appearance of the top AppBar.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.lightText, // Color for title and icons in AppBar
      ),
      // Configures the default appearance of all ElevatedButton widgets.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          // Define properties using MaterialStateProperty to handle different states (hover, pressed, etc.)
          backgroundColor: MaterialStateProperty.all(AppColors.lightText),
          foregroundColor: MaterialStateProperty.all(AppColors.darkText),
          overlayColor: MaterialStateProperty.all(Colors.transparent), // Make hover/press overlay transparent
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
          ),
          textStyle: MaterialStateProperty.all(AppTextStyles.googleButton),
          elevation: MaterialStateProperty.all(2),
          // Ensure the default shape is StadiumBorder if needed globally
          shape: MaterialStateProperty.all(const StadiumBorder()), 
        ),
      ),
      // Defines default styles for common text types (headlines, body text, etc.).
      // Widgets like `Text` can automatically use these based on context,
      // or you can reference them explicitly like `Theme.of(context).textTheme.headlineLarge`.
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.title, 
        bodyLarge: AppTextStyles.slogan,
        headlineMedium: AppTextStyles.welcomeMessage,
      ),
    );
  }
}

// --- Asset Path Definitions ---
// Defines constants for the paths to image assets used in the app.
// This prevents typos and makes it easy to manage asset locations.
class AppAssets {
  static const String googleLogo = 'assets/google_logo.png';
  static const String blueberry = 'assets/fruits/blueberry.png';
  static const String strawberry = 'assets/fruits/strawberry.png';
  static const String broccoli = 'assets/fruits/broccoli.png';
  static const String carrot = 'assets/fruits/carrot.png';
  static const String cucumber = 'assets/fruits/cucumber.png';
  static const String tomato = 'assets/fruits/tomato.png';
} 