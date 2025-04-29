import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cursor_fitchef/screens/login_screen.dart'; // Import to access FallingFruit and useImages
import 'package:cursor_fitchef/constants/app_theme.dart'; // Import theme

class FallingFruitWidget extends StatelessWidget {
  final FallingFruit fruit;
  final Animation<double> animation;
  final double screenHeight;

  const FallingFruitWidget({
    super.key,
    required this.fruit,
    required this.animation,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Positioned(
          // Use fruit properties for initial position and animation value for movement
          left: fruit.x + (math.sin(animation.value * 2 * math.pi) * 20), // Horizontal sway
          top: (fruit.y + animation.value * screenHeight) % screenHeight, // Vertical falling
          child: Transform.rotate(
            angle: animation.value * 2 * math.pi * fruit.rotationSpeed, // Rotation
            child: _buildFruitRepresentation(context), // Pass context
          ),
        );
      },
    );
  }

  Widget _buildFruitRepresentation(BuildContext context) {
    // Use theme color for fruit text/emoji
    final fruitTextStyle = TextStyle(
      fontSize: fruit.size,
      color: AppColors.fruitText, // Use defined color constant
    );

    // Determine whether to show image or emoji based on the constant
    if (useImages) {
      return Image.asset(
        fruit.imageAsset,
        width: fruit.size,
        height: fruit.size,
        // Fallback to emoji if image fails to load
        errorBuilder: (context, error, stackTrace) => Text(
          fruit.emoji,
          style: fruitTextStyle,
        ),
      );
    } else {
      return Text(
        fruit.emoji,
        style: fruitTextStyle,
      );
    }
  }
} 