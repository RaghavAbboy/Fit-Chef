import 'dart:math' as math;
import 'package:cursor_fitchef/constants/app_theme.dart';
import 'package:cursor_fitchef/widgets/falling_fruit_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Constants
const bool useImages = false; // Set this to true to use images instead of emojis
final math.Random globalRandom = math.Random(42);
final supabaseRedirectUri = Uri.base.origin;

abstract class FallingFruit {
  final double x;
  final double y;
  final double size;
  final double rotationSpeed;

  FallingFruit(math.Random random)
      : x = random.nextDouble() * 1000, // Consider using MediaQuery for width
        y = random.nextDouble() * 800, // Consider using MediaQuery for height
        size = 15 + random.nextDouble() * 25,
        rotationSpeed = 0.2 + random.nextDouble() * 1.0;
        // Removed debug print

  String get emoji;
  String get imageAsset;
}

class FallingLeavesScreen extends StatefulWidget {
  const FallingLeavesScreen({super.key});

  @override
  _FallingLeavesScreenState createState() => _FallingLeavesScreenState();
}

class _FallingLeavesScreenState extends State<FallingLeavesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<FallingFruit> fruits;
  static const int _numberOfFruits = 40;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Use the same random instance for all fruits
    fruits = List.generate(
      _numberOfFruits,
      (index) {
        // Simplified fruit distribution logic
        final typeIndex = index % 6;
        switch (typeIndex) {
          case 0: return FallingBlueberry(globalRandom);
          case 1: return FallingStrawberry(globalRandom);
          case 2: return FallingBroccoli(globalRandom);
          case 3: return FallingCarrot(globalRandom);
          case 4: return FallingCucumber(globalRandom);
          default: return FallingTomato(globalRandom);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Use the environment-specific redirect URI
      final res = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: supabaseRedirectUri,
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      
      if (!res) {
         // ignore: use_build_context_synchronously
         if (!context.mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled or failed')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Access theme data
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // No need to set color explicitly, handled by theme
      body: Stack(
        children: [
          // Background color is handled by Scaffold theme
          // Container(color: theme.scaffoldBackgroundColor),
          ...fruits.map((fruit) {
            return FallingFruitWidget(
              fruit: fruit,
              animation: _controller,
              screenHeight: screenHeight,
            );
          }).toList(), 
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(
                  'Fit Chef',
                  // Use headlineLarge from theme
                  style: textTheme.headlineLarge,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70.0, vertical: 16.0),
                  child: Text(
                    'Your gateway to feeling and looking fit!',
                    textAlign: TextAlign.center,
                    // Use bodyLarge from theme
                    style: textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  // Use asset constant
                  icon: Image.asset(
                    AppAssets.googleLogo, 
                    width: 24,
                    height: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  // Style is now handled by ElevatedButtonTheme in AppTheme
                  // style: ElevatedButton.styleFrom(...),
                  onPressed: _signInWithGoogle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Falling Fruit Definitions ---

class FallingBlueberry extends FallingFruit {
  FallingBlueberry(super.random);
  @override
  String get emoji => '🫐';
  @override
  String get imageAsset => AppAssets.blueberry; // Use constant
}

class FallingStrawberry extends FallingFruit {
  FallingStrawberry(super.random);
  @override
  String get emoji => '🍓';
  @override
  String get imageAsset => AppAssets.strawberry; // Use constant
}

class FallingBroccoli extends FallingFruit {
  FallingBroccoli(super.random);
  @override
  String get emoji => '🥦';
  @override
  String get imageAsset => AppAssets.broccoli; // Use constant
}

class FallingCarrot extends FallingFruit {
  FallingCarrot(super.random);
  @override
  String get emoji => '🥕';
  @override
  String get imageAsset => AppAssets.carrot; // Use constant
}

class FallingCucumber extends FallingFruit {
  FallingCucumber(super.random);
  @override
  String get emoji => '🥒';
  @override
  String get imageAsset => AppAssets.cucumber; // Use constant
}

class FallingTomato extends FallingFruit {
  FallingTomato(super.random);
  @override
  String get emoji => '🍅';
  @override
  String get imageAsset => AppAssets.tomato; // Use constant
} 