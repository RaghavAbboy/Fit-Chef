import 'package:cursor_fitchef/constants/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    // Fetch user name safely
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'User';
    // Use theme for text style
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // AppBar theme is handled globally
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Add error handling for sign out
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (e) {
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
      body: Center(
        child: Text(
          'Welcome, $userName!',
          // Use headlineMedium style from theme
          style: textTheme.headlineMedium,
        ),
      ),
    );
  }
} 