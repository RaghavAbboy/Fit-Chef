import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FallingLeavesScreen(),
    );
  }
}

class FallingLeavesScreen extends StatefulWidget {
  @override
  _FallingLeavesScreenState createState() => _FallingLeavesScreenState();
}

class _FallingLeavesScreenState extends State<FallingLeavesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FallingFruit> fruits = List.generate(
    40,
    (index) {
      if (index < 8) return FallingBlueberry();
      if (index < 16) return FallingStrawberry();
      if (index < 22) return FallingBroccoli();
      if (index < 28) return FallingCarrot();
      if (index < 34) return FallingCucumber();
      return FallingTomato();
    },
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  Color(0xFFC8E6C9),
                ],
              ),
            ),
          ),
          // Falling fruits and vegetables
          ...fruits.map((fruit) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned(
                  left: fruit.x +
                      (math.sin(_controller.value * 2 * math.pi) * 20),
                  top: (fruit.y +
                          _controller.value *
                              MediaQuery.of(context).size.height) %
                      MediaQuery.of(context).size.height,
                  child: Transform.rotate(
                    angle:
                        _controller.value * 2 * math.pi * fruit.rotationSpeed,
                    child: Text(
                      fruit.emoji,
                      style: TextStyle(
                        fontSize: fruit.size,
                        color: Colors.black.withAlpha(153),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
          // Text content
          Container(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.3), // Adjust this value to move text up/down
                Text(
                  'Fit Chef',
                  style: TextStyle(
                    fontSize: 64,
                    fontFamily: 'Pacifico',
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B5E20),
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 3.0,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 70.0),
                  child: Text(
                    'Your gateway to feeling and looking fit!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2.0,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

abstract class FallingFruit {
  late final double x;
  late final double y;
  late final double size;
  late final double rotationSpeed;

  FallingFruit() {
    x = math.Random().nextDouble() * 1000;
    y = math.Random().nextDouble() * 800;
    size = 20 + math.Random().nextDouble() * 12;
    rotationSpeed = 0.5 + math.Random().nextDouble() * 2;
  }

  String get emoji;
}

class FallingBlueberry extends FallingFruit {
  @override
  String get emoji => '🫐';
}

class FallingStrawberry extends FallingFruit {
  @override
  String get emoji => '🍓';
}

class FallingBroccoli extends FallingFruit {
  @override
  String get emoji => '🥦';
}

class FallingCarrot extends FallingFruit {
  @override
  String get emoji => '🥕';
}

class FallingCucumber extends FallingFruit {
  @override
  String get emoji => '🥒';
}

class FallingTomato extends FallingFruit {
  @override
  String get emoji => '🍅';
}
