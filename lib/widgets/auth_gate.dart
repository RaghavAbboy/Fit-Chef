import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cursor_fitchef/screens/home_page.dart';
import 'package:cursor_fitchef/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        // Use const for constructor calls where possible
        return session != null ? const HomePage() : const FallingLeavesScreen();
      },
    );
  }
} 