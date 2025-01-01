import 'package:flutter/material.dart';

class FallingObject extends StatelessWidget {
  final double x;
  final double y;

  const FallingObject({
    required this.x,
    required this.y,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: Text(
        '🫐',
        style: TextStyle(
          fontSize: 24,
        ),
      ),
    );
  }
}
