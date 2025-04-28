import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

// The redirect URI is determined by the current origin (localhost or production)
// This ensures OAuth flow returns to the same environment where it was initiated
final supabaseRedirectUri = kIsWeb ? Uri.base.origin : null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://daoqplvfscgawerappav.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhb3FwbHZmc2NnYXdlcmFwcGF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU3MDk3MjcsImV4cCI6MjA2MTI4NTcyN30.0MFnjpcupSAmpRQCn0t3TRIIGlI5wGgl-IgZlgCJdm4',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        return session != null ? HomePage() : FallingLeavesScreen();
      },
    );
  }
}

// Set this to true to use images instead of emojis (make sure assets exist)
const bool useImages = false;

final math.Random globalRandom =
    math.Random(42); // Fixed seed for reproducibility

abstract class FallingFruit {
  final double x;
  final double y;
  final double size;
  final double rotationSpeed;

  FallingFruit(math.Random random)
      : x = random.nextDouble() * 1000,
        y = random.nextDouble() * 800,
        size = 15 + random.nextDouble() * 25,
        rotationSpeed = 0.2 + random.nextDouble() * 1.0 {
    // Debug log for reproducibility
    // ignore: avoid_print
    print(
        '${runtimeType.toString()} - x: $x, y: $y, size: $size, rotationSpeed: $rotationSpeed');
  }

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    // Use the same random instance for all fruits
    fruits = List.generate(
      40,
      (index) {
        if (index < 8) return FallingBlueberry(globalRandom);
        if (index < 16) return FallingStrawberry(globalRandom);
        if (index < 22) return FallingBroccoli(globalRandom);
        if (index < 28) return FallingCarrot(globalRandom);
        if (index < 34) return FallingCucumber(globalRandom);
        return FallingTomato(globalRandom);
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
      final res = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: supabaseRedirectUri,  // Uses the environment-specific redirect URI
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      
      if (!res) {
        throw Exception('Failed to initiate Google sign-in');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
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
                    child: useImages
                        ? Image.asset(
                            fruit.imageAsset,
                            width: fruit.size,
                            height: fruit.size,
                            errorBuilder: (context, error, stackTrace) => Text(
                              fruit.emoji,
                              style: TextStyle(
                                fontSize: fruit.size,
                                color: Colors.black.withAlpha(153),
                              ),
                            ),
                          )
                        : Text(
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
          }),
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
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
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/google_logo.png',
                    width: 24,
                    height: 24,
                  ),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    elevation: 2,
                  ),
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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'User';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome, $userName!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class FallingBlueberry extends FallingFruit {
  FallingBlueberry(super.random);
  @override
  String get emoji => '🫐';
  @override
  String get imageAsset => 'assets/fruits/blueberry.png';
}

class FallingStrawberry extends FallingFruit {
  FallingStrawberry(super.random);
  @override
  String get emoji => '🍓';
  @override
  String get imageAsset => 'assets/fruits/strawberry.png';
}

class FallingBroccoli extends FallingFruit {
  FallingBroccoli(super.random);
  @override
  String get emoji => '🥦';
  @override
  String get imageAsset => 'assets/fruits/broccoli.png';
}

class FallingCarrot extends FallingFruit {
  FallingCarrot(super.random);
  @override
  String get emoji => '🥕';
  @override
  String get imageAsset => 'assets/fruits/carrot.png';
}

class FallingCucumber extends FallingFruit {
  FallingCucumber(super.random);
  @override
  String get emoji => '🥒';
  @override
  String get imageAsset => 'assets/fruits/cucumber.png';
}

class FallingTomato extends FallingFruit {
  FallingTomato(super.random);
  @override
  String get emoji => '🍅';
  @override
  String get imageAsset => 'assets/fruits/tomato.png';
}
