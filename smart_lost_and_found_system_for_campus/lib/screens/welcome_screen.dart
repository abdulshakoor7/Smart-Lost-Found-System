import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart'; // Ensure these files exist in the same folder
import 'signup_screen.dart';
import 'package:flutter/gestures.dart'; // Required for TapGestureRecognizer

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key}); // Standard key syntax

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _searchController;
  late AnimationController _iconsController;
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _searchScale;
  late Animation<double> _searchRotate;
  late Animation<double> _iconsFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _searchController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _searchScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _searchController, curve: Curves.elasticOut));
    _searchRotate = Tween<double>(begin: -0.5, end: 0.0).animate(
        CurvedAnimation(parent: _searchController, curve: Curves.easeOutBack));

    _iconsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _iconsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconsController, curve: Curves.easeIn));

    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textController, curve: Curves.easeOutCubic));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _buttonController, curve: Curves.easeOutBack));
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeIn));

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _startAnimations();
  }

  void _startAnimations() async {
    await _searchController.forward();
    _iconsController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();
    await _buttonController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _iconsController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        // --- FIX: Wrap in SingleChildScrollView to prevent overflow ---
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: Column(
                children: [
                  // 1. Animated Logo
                  SizedBox(
                    height: 240, // Slightly reduced to save space
                    width: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FadeTransition(
                            opacity: _iconsFade, child: _buildFloatingIcons()),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 160 * _pulseAnimation.value,
                              height: 160 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.3),
                                    width: 2),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _searchController,
                          builder: (context, child) => Transform.scale(
                            scale: _searchScale.value,
                            child: Transform.rotate(
                                angle: _searchRotate.value, child: child),
                          ),
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [
                                Color(0xFF2563EB),
                                Color(0xFF3B82F6)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 30)
                              ],
                            ),
                            child: const Icon(Icons.search_rounded,
                                size: 60, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 2. Title Section
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            'SmartFind',
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'UOG Lost & Found System',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Lost something on campus?\nReport, search, and reunite with your belongings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 3. Feature Pills
                  FadeTransition(
                    opacity: _textFade,
                    child: Wrap(
                      // Changed to Wrap for better responsiveness
                      spacing: 10, runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeaturePill(
                            Icons.report_gmailerrorred_outlined, 'Report'),
                        _buildFeaturePill(Icons.auto_awesome, 'AI Match'),
                        _buildFeaturePill(
                            Icons.verified_user_outlined, 'Recover'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // 4. Buttons
                  SlideTransition(
                    position: _buttonSlide,
                    child: FadeTransition(
                      opacity: _buttonFade,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => const SignupScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text('Get Started',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // --- REPLACE THE TEXT BUTTON WITH THIS ---
                          FadeTransition(
                            opacity: _buttonFade,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontFamily: 'Inter', // Or your default font
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign In',
                                      style: const TextStyle(
                                        color: Color(0xFF3B82F6),
                                        // Vibrant Blue
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration
                                            .underline, // Visual cue for a link
                                      ),
                                      // --- THIS PART MAKES ONLY 'SIGN IN' CLICKABLE ---
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (c) =>
                                                    const LoginScreen()),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcons() {
    final items = [
      Icons.key,
      Icons.phone_android,
      Icons.watch,
      Icons.backpack,
      Icons.credit_card,
      Icons.book
    ];
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(items.length, (i) {
            final angle = (i * 60) * math.pi / 180;
            final radius =
                100 + (5 * math.sin(_pulseController.value * math.pi));
            return Transform.translate(
              offset:
                  Offset(radius * math.cos(angle), radius * math.sin(angle)),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(items[i], color: Colors.white70, size: 18),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
