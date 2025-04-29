// --- Imports ---
// Import Flutter UI elements, Supabase for auth state, and the screen widgets.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cursor_fitchef/screens/home_page.dart';
import 'package:cursor_fitchef/screens/login_screen.dart';

// --- Authentication Gate Widget ---
// This widget acts as a gatekeeper, deciding which screen to show based on
// whether the user is currently logged in or not.
class AuthGate extends StatelessWidget {
  // Constructor for the AuthGate widget.
  const AuthGate({super.key});

  // The `build` method determines the UI based on the authentication state.
  @override
  Widget build(BuildContext context) {
    // `StreamBuilder` listens to changes in the Supabase authentication state.
    // Whenever the user logs in or out, this builder function will re-run.
    return StreamBuilder<AuthState>(
      // `onAuthStateChange` is a stream from Supabase that emits events
      // whenever the authentication state (logged in, logged out) changes.
      stream: Supabase.instance.client.auth.onAuthStateChange,
      // The `builder` function builds the UI based on the latest event from the stream.
      builder: (context, snapshot) {
        // Get the current user session from Supabase.
        // `currentSession` is null if the user is not logged in.
        final session = Supabase.instance.client.auth.currentSession;
        
        // --- Conditional Navigation ---
        // If `session` is not null (meaning the user is logged in),
        // show the `HomePage`.
        // Otherwise (user is logged out), show the `FallingLeavesScreen` (login screen).
        // Using `const` improves performance by reusing the same widget instances.
        return session != null ? const HomePage() : const FallingLeavesScreen();
      },
    );
  }
} 