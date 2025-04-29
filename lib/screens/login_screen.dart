// --- Imports ---
// Import libraries for math (random numbers), theme constants, the falling fruit widget,
// Flutter UI elements, and Supabase for authentication.
import 'dart:math' as math;
import 'package:cursor_fitchef/constants/app_theme.dart';
import 'package:cursor_fitchef/widgets/falling_fruit_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Screen Constants ---
// `useImages`: Toggle between showing fruit images (true) or emojis (false).
//              Requires corresponding image assets in `assets/fruits/`.
const bool useImages = false;
// `globalRandom`: A single random number generator instance used for all fruits
//                 to ensure consistent initial positions if needed (or for debugging).
//                 Using a fixed seed (42) makes the randomness predictable during development.
final math.Random globalRandom = math.Random(42);
// `supabaseRedirectUri`: The URL where Google sign-in should redirect back to.
//                      `Uri.base.origin` automatically uses the correct address
//                      whether running locally (e.g., http://localhost:3000) or deployed.
final supabaseRedirectUri = Uri.base.origin;

// --- FallingFruit Base Class ---
// An abstract class defines a blueprint for other classes.
// It cannot be instantiated directly.
// This defines the common properties and constructor for all falling items.
abstract class FallingFruit {
  // `final` means these properties are set once in the constructor and cannot be changed.
  final double x; // Initial horizontal position (percentage of screen width, effectively)
  final double y; // Initial vertical position (percentage of screen height, effectively)
  final double size; // Size of the fruit (used for font size or image dimensions)
  final double rotationSpeed; // How fast the fruit rotates

  // Constructor: Initializes a new FallingFruit object.
  // It takes a `Random` generator to determine the initial properties randomly.
  FallingFruit(math.Random random)
      // These lines set the initial values using the random generator.
      // `random.nextDouble()` gives a value between 0.0 and 1.0.
      : x = random.nextDouble() * 1000, // Initial x position (needs adjustment for screen width)
        y = random.nextDouble() * 800, // Initial y position (needs adjustment for screen height)
        size = 15 + random.nextDouble() * 25, // Size between 15 and 40
        rotationSpeed = 0.2 + random.nextDouble() * 1.0; // Rotation speed between 0.2 and 1.2

  // Abstract methods: These must be implemented by any class that extends FallingFruit.
  String get emoji; // Returns the emoji character for the fruit.
  String get imageAsset; // Returns the asset path for the fruit's image.
}

// --- Login Screen Widget ---
// This is the main widget for the login/landing screen.
// It's a `StatefulWidget` because its appearance changes over time (the animation).
class FallingLeavesScreen extends StatefulWidget {
  const FallingLeavesScreen({super.key});

  // Creates the mutable state for this widget.
  @override
  _FallingLeavesScreenState createState() => _FallingLeavesScreenState();
}

// --- Login Screen State ---
// This class holds the state and logic for the `FallingLeavesScreen`.
// `with SingleTickerProviderStateMixin` is needed for the `AnimationController`.
class _FallingLeavesScreenState extends State<FallingLeavesScreen>
    with SingleTickerProviderStateMixin {
  // `late` means these variables will be initialized before they are used.
  late AnimationController _controller; // Manages the animation timing.
  late final List<FallingFruit> fruits; // List to hold all the falling fruit objects.
  static const int _numberOfFruits = 40; // How many fruits to display.

  // `initState` is called once when the widget is first created.
  // Used for setup tasks.
  @override
  void initState() {
    super.initState();
    // Initialize the animation controller.
    _controller = AnimationController(
      vsync: this, // Links the controller to this widget's state.
      duration: const Duration(seconds: 10), // Animation duration (one cycle).
    )..repeat(); // Make the animation loop continuously.

    // Create the list of fruit objects.
    fruits = List.generate(
      _numberOfFruits,
      (index) {
        // Distribute fruit types somewhat evenly using the modulo operator (%).
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

  // `dispose` is called when the widget is permanently removed from the screen.
  // Used for cleanup tasks to prevent memory leaks.
  @override
  void dispose() {
    _controller.dispose(); // Dispose of the animation controller.
    super.dispose();
  }

  // --- Google Sign-In Logic ---
  // This function handles the Google sign-in process using Supabase.
  Future<void> _signInWithGoogle() async {
    try {
      // Initiates the Google OAuth flow provided by Supabase.
      final res = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google, // Specify Google as the provider.
        redirectTo: supabaseRedirectUri, // The URL to return to after sign-in.
        // Additional parameters for the Google OAuth request.
        queryParams: {
          'access_type': 'offline', // Request offline access (refresh token).
          'prompt': 'consent', // Force the consent screen (useful for testing).
        },
      );
      
      // `res` is false if the user cancelled the sign-in flow from Google's side.
      if (!res) {
         // Show a message if the sign-in was cancelled.
         // Check `context.mounted` before showing UI elements in async methods.
         // ignore: use_build_context_synchronously
         if (!context.mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled or failed')),
        );
      }
      // If sign-in is successful, Supabase handles the redirect and the
      // `AuthGate` widget will automatically navigate to the `HomePage`.
    } catch (e) {
      // Catch any errors during the sign-in process (network issues, etc.).
      // ignore: use_build_context_synchronously
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in error: $e')),
      );
    }
  }

  // --- Build Method ---
  // Describes the UI for the login screen.
  @override
  Widget build(BuildContext context) {
    // Get screen height for positioning calculations.
    final screenHeight = MediaQuery.of(context).size.height;
    // Get theme data for styling.
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // `Scaffold` provides the basic screen structure.
    return Scaffold(
      // `Stack` allows layering widgets on top of each other.
      body: Stack(
        children: [
          // Layer 1: Background (implicitly white via theme's scaffoldBackgroundColor)
          
          // Layer 2: Falling fruits animation
          // Create a `FallingFruitWidget` for each fruit in the list.
          ...fruits.map((fruit) {
            return FallingFruitWidget(
              fruit: fruit,
              animation: _controller, // Pass the animation controller.
              screenHeight: screenHeight, // Pass screen height for positioning.
            );
          }).toList(), // `.map` creates an Iterable, `.toList()` converts it to a List of widgets.
          
          // Layer 3: UI elements (Title, Slogan, Button)
          SizedBox(
            width: double.infinity, // Take full width
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center content vertically.
              children: [
                // App Title
                Text(
                  'Fit Chef',
                  style: textTheme.headlineLarge, // Use style from theme.
                ),
                // Slogan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70.0, vertical: 16.0),
                  child: Text(
                    'Your gateway to feeling and looking fit!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge, // Use style from theme.
                  ),
                ),
                const SizedBox(height: 32), // Spacing
                // Google Sign-In Button
                ElevatedButton.icon(
                  icon: Image.asset(
                    AppAssets.googleLogo, // Use asset path from constants.
                    width: 24,
                    height: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  // Button style is automatically applied from the theme.
                  onPressed: _signInWithGoogle, // Call the sign-in function when pressed.
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Concrete Falling Fruit Classes ---
// These classes extend `FallingFruit` and provide the specific emoji
// and image asset path for each type of fruit/vegetable.

class FallingBlueberry extends FallingFruit {
  FallingBlueberry(super.random); // Calls the parent constructor
  @override
  String get emoji => '🫐';
  @override
  String get imageAsset => AppAssets.blueberry;
}

class FallingStrawberry extends FallingFruit {
  FallingStrawberry(super.random);
  @override
  String get emoji => '🍓';
  @override
  String get imageAsset => AppAssets.strawberry;
}

class FallingBroccoli extends FallingFruit {
  FallingBroccoli(super.random);
  @override
  String get emoji => '🥦';
  @override
  String get imageAsset => AppAssets.broccoli;
}

class FallingCarrot extends FallingFruit {
  FallingCarrot(super.random);
  @override
  String get emoji => '🥕';
  @override
  String get imageAsset => AppAssets.carrot;
}

class FallingCucumber extends FallingFruit {
  FallingCucumber(super.random);
  @override
  String get emoji => '🥒';
  @override
  String get imageAsset => AppAssets.cucumber;
}

class FallingTomato extends FallingFruit {
  FallingTomato(super.random);
  @override
  String get emoji => '🍅';
  @override
  String get imageAsset => AppAssets.tomato;
} 