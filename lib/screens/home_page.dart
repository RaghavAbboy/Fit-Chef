// --- Imports ---
// Import necessary libraries: theme constants, Flutter UI elements, and Supabase for auth.
import 'package:cursor_fitchef/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Home Page Widget ---
// This widget represents the main screen users see after logging in.
class HomePage extends StatelessWidget {
  // Constructor for the HomePage widget.
  const HomePage({super.key});

  // The `build` method describes the UI for this screen.
  @override
  Widget build(BuildContext context) {
    // --- Get User Information ---
    // Access the currently logged-in user details from Supabase.
    final user = Supabase.instance.client.auth.currentUser;
    // Safely get the user's name: use the name from their profile if available,
    // otherwise fall back to their email, or default to 'User' if neither exists.
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'User';
    
    // Get the text theme defined in `app_theme.dart` for consistent styling.
    final textTheme = Theme.of(context).textTheme;

    // --- Build the UI ---
    // `Scaffold` provides a basic app screen layout (app bar, body).
    return Scaffold(
      // `AppBar` is the top bar of the screen.
      // Its appearance is largely controlled by the `appBarTheme` in `app_theme.dart`.
      appBar: AppBar(
        // Title displayed in the AppBar.
        title: const Text('Home'),
        // `actions` are widgets placed on the right side of the AppBar.
        actions: [
          // An icon button for logging out.
          IconButton(
            icon: const Icon(Icons.logout), // The logout icon.
            tooltip: 'Logout', // Text shown when hovering over the button (web/desktop).
            // Function to execute when the button is pressed.
            onPressed: () async {
              // Attempt to sign the user out using Supabase.
              try {
                await Supabase.instance.client.auth.signOut();
                // If sign-out is successful, the `AuthGate` will automatically
                // navigate the user back to the login screen.
              } catch (e) {
                // If sign-out fails, show an error message.
                // `context.mounted` checks if the widget is still part of the UI
                // before trying to show the SnackBar (prevents errors).
                // ignore: use_build_context_synchronously 
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign out failed: $e')),
                );
              }
            },
          ),
        ],
      ),
      // `body` is the main content area of the screen.
      body: Center( // Centers its child widget.
        // Displays the welcome message.
        child: Text(
          'Welcome, $userName!', // Shows the fetched user name.
          // Apply the `welcomeMessage` style defined in `app_theme.dart`.
          style: textTheme.headlineMedium,
        ),
      ),
    );
  }
} 