import 'package:cursor_fitchef/constants/app_theme.dart';
import 'package:cursor_fitchef/widgets/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The redirect URI is determined by the current origin (localhost or production)
// This ensures OAuth flow returns to the same environment where it was initiated
// final supabaseRedirectUri = kIsWeb ? Uri.base.origin : null; // Moved to login_screen.dart

// Constants for Supabase credentials - consider using environment variables
const String supabaseUrl = 'https://daoqplvfscgawerappav.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhb3FwbHZmc2NnYXdlcmFwcGF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3MDk3MjcsImV4cCI6MjA2MTI4NTcyN30.0MFnjpcupSAmpRQCn0t3TRIIGlI5wGgl-IgZlgCJdm4';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(), 
    );
  }
}

// Removed duplicate AuthGate class
// Removed duplicate FallingFruit classes and related constants/variables
// ... (rest of file should be empty after this)
