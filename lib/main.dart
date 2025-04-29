// --- Imports ---
// These lines import necessary code libraries for the app.
// `material.dart` provides Flutter UI elements.
// `supabase_flutter` is for backend services (like login).
// Other imports bring in custom widgets and theme settings from this project.
import 'package:cursor_fitchef/constants/app_theme.dart';
import 'package:cursor_fitchef/widgets/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Supabase Configuration ---
// These constants hold the connection details for Supabase, the backend service.
// Ideally, these should be stored securely (e.g., environment variables)
// instead of directly in the code, especially for non-public keys.
const String supabaseUrl = 'https://daoqplvfscgawerappav.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhb3FwbHZmc2NnYXdlcmFwcGF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3MDk3MjcsImV4cCI6MjA2MTI4NTcyN30.0MFnjpcupSAmpRQCn0t3TRIIGlI5wGgl-IgZlgCJdm4';

// --- Main Function ---
// This is the starting point of the Flutter application.
void main() async {
  // Ensures that Flutter is ready before doing anything else.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connects to the Supabase backend service using the URL and key defined above.
  // `await` means the app waits for this connection to complete before proceeding.
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Starts the Flutter app by running the main widget `MyApp`.
  runApp(const MyApp());
}

// --- Root Application Widget ---
// `MyApp` is the main widget that represents the entire application.
// It sets up the overall structure and appearance.
class MyApp extends StatelessWidget {
  // `const MyApp({super.key});` is the constructor for this widget.
  // `super.key` passes a unique identifier to the parent class.
  const MyApp({super.key});

  // The `build` method describes how to draw the widget on the screen.
  @override
  Widget build(BuildContext context) {
    // `MaterialApp` is a standard Flutter widget that provides
    // many basic app features like navigation and theming.
    return MaterialApp(
      // Hides the debug banner shown in the top-right corner during development.
      debugShowCheckedModeBanner: false,
      // Applies the custom theme defined in `app_theme.dart`.
      theme: AppTheme.lightTheme,
      // Sets the initial screen of the app to be the `AuthGate` widget.
      // `AuthGate` will decide whether to show the login screen or home screen.
      home: const AuthGate(), 
    );
  }
}

// Removed duplicate AuthGate class
// Removed duplicate FallingFruit classes and related constants/variables
// ... (rest of file should be empty after this)
