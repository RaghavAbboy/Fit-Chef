// --- Imports ---
// Import libraries for math, Flutter UI, login screen (for FallingFruit), and theme constants.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cursor_fitchef/screens/login_screen.dart'; // Provides FallingFruit definition and useImages constant
import 'package:cursor_fitchef/constants/app_theme.dart'; // Provides AppColors and AppAssets

// --- Falling Fruit Widget ---
// This widget is responsible for displaying and animating a single falling fruit (or vegetable).
// It takes the fruit data, the animation progress, and screen height as input.
class FallingFruitWidget extends StatelessWidget {
  // --- Properties ---
  // `final` means these cannot be changed after the widget is created.
  final FallingFruit fruit; // The data object containing fruit details (position, size, type).
  final Animation<double> animation; // The animation controller's value (typically 0.0 to 1.0).
  final double screenHeight; // The height of the screen, used for positioning.

  // --- Constructor ---
  // Creates a FallingFruitWidget.
  // `required` means these parameters must be provided when creating the widget.
  const FallingFruitWidget({
    super.key, // Standard Flutter widget key.
    required this.fruit,
    required this.animation,
    required this.screenHeight,
  });

  // --- Build Method ---
  // Describes how to draw this individual fruit widget.
  @override
  Widget build(BuildContext context) {
    // `AnimatedBuilder` rebuilds its child whenever the animation value changes.
    // This is efficient because only the changing parts (Positioned, Transform.rotate)
    // need to be redrawn, not the entire screen.
    return AnimatedBuilder(
      animation: animation, // Listens to the main animation controller.
      // The `builder` function creates the actual widget that animates.
      builder: (context, child) {
        // `Positioned` places the fruit at a specific location within the Stack.
        return Positioned(
          // Calculate the horizontal position:
          // `fruit.x` is the base position.
          // `math.sin(...) * 20` creates a gentle side-to-side swaying motion based on animation progress.
          left: fruit.x + (math.sin(animation.value * 2 * math.pi) * 20),
          // Calculate the vertical position:
          // `fruit.y` is the base vertical position.
          // `animation.value * screenHeight` moves the fruit down the screen as animation progresses.
          // `% screenHeight` makes the fruit wrap around from bottom to top when it goes off-screen.
          top: (fruit.y + animation.value * screenHeight) % screenHeight,
          // `Transform.rotate` rotates the fruit.
          child: Transform.rotate(
            // Calculate the rotation angle:
            // `animation.value * 2 * math.pi` converts the 0.0-1.0 animation value to a full circle (radians).
            // `* fruit.rotationSpeed` applies the individual fruit's rotation speed.
            angle: animation.value * 2 * math.pi * fruit.rotationSpeed,
            // The actual visual representation (Image or Text) of the fruit.
            child: _buildFruitRepresentation(context), 
          ),
        );
      },
    );
  }

  // --- Helper Method: Build Fruit Visual ---
  // This private helper method decides whether to show an Image or Text for the fruit.
  Widget _buildFruitRepresentation(BuildContext context) {
    // Define the text style for the fruit (used for emoji or as image fallback).
    final fruitTextStyle = TextStyle(
      fontSize: fruit.size, // Use the fruit's specific size.
      color: AppColors.fruitText, // Use the semi-transparent color from the theme.
    );

    // Check the global `useImages` constant (defined in login_screen.dart).
    if (useImages) {
      // If true, display an `Image` widget.
      return Image.asset(
        fruit.imageAsset, // Get the asset path from the fruit object (uses AppAssets).
        width: fruit.size,
        height: fruit.size,
        // `errorBuilder` provides a fallback if the image fails to load.
        // In this case, it falls back to showing the emoji.
        errorBuilder: (context, error, stackTrace) => Text(
          fruit.emoji,
          style: fruitTextStyle,
        ),
      );
    } else {
      // If false, display a `Text` widget with the fruit's emoji.
      return Text(
        fruit.emoji,
        style: fruitTextStyle,
      );
    }
  }
} 