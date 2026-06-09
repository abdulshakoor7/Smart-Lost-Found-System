import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http; // ✅ Added for Django Auth
import 'dart:convert'; // ✅ Added for JSON parsing
import '../services/api_service.dart'; // ✅ Added to access baseUrl
import '../user_session.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // --- FIGMA THEME COLORS ---
  final Color _bgDeep = const Color(0xFF0F172A);
  final Color _cardBg = const Color(0xFF1E293B);
  final Color _vibrantBlue = const Color(0xFF3B82F6);
  final Color _textGrey = const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- SECURE LOGIN FUNCTION (UPDATED WITH DJANGO TOKEN SYNC) ---
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 1. ADMIN CHECK (PRESERVED)
      if (email == 'admin@uog.edu.pk' && password == 'admin123') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        }
        return;
      }

      // 2. FIREBASE STUDENT LOGIN (PRESERVED)
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password
        );

        // --- VERIFICATION CHECK (PRESERVED) ---
        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email address before logging in. Check your inbox.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // --- ✅ NEW LOGIC: DJANGO BACKEND TOKEN SYNCHRONIZATION ---
        // This ensures the token is saved for Django REST API calls (like privacy settings)
        // --- ✅ DJANGO BACKEND TOKEN SYNCHRONIZATION ---
        try {
          final syncResponse = await http.post(
            Uri.parse("${ApiService.baseUrl}/auth-sync/"), // If baseUrl has /api, this is correct.
            headers: ApiService.headers,
            body: jsonEncode({"email": email}),
          ).timeout(const Duration(seconds: 10)); // ✅ ADD TIMEOUT
          if (syncResponse.statusCode == 200) {
            final syncData = jsonDecode(syncResponse.body);
            // ✅ THE KEY MUST MATCH: If Django returns "token", use "token"
            UserSession.token = syncData['token'];
            UserSession.email = syncData['email'];
            debugPrint("🚀 BRIDGE SUCCESS: Token is now ${UserSession.token}");
          }
          else
          {
            debugPrint("❌ ERROR 404/500: URL or Logic mismatch");
          }

        }
        catch (e)
        {
          debugPrint("❌ CONNECTION ERROR: $e");
        }


        // Success: Update Global Session Data (PRESERVED)
        UserSession.email = email;
        UserSession.name = userCredential.user?.displayName ?? email.split('@')[0];

        // --- FETCH REAL DATA FROM FIRESTORE (PRESERVED) ---
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          debugPrint("📂 Firestore Data Found: $userData");
          UserSession.email = email;
          UserSession.name = userData?['name'] ?? "Student";
          UserSession.phone = userData?['phone'] ?? "";
          UserSession.studentId = userData?['student_id'] ?? "N/A";
          UserSession.photoUrl = userData?['photo_url'] ?? "";
          debugPrint("✅ Image URL loaded from DB: ${UserSession.photoUrl}");
        } else {
          UserSession.email = email;
          UserSession.name = email.split('@')[0];
          UserSession.phone = "No Phone";
          UserSession.studentId = "N/A";
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = "Login Failed";
        if (e.code == 'user-not-found') {
          message = "No account found with this email.";
        } else if (e.code == 'wrong-password') {
          message = "Incorrect password.";
        } else if (e.code == 'invalid-credential') {
          message = "Invalid email or password.";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("An error occurred: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(
        children: [
          // Dynamic Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgDeep, const Color(0xFF1E1B4B)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _vibrantBlue.withValues(alpha:0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _vibrantBlue.withValues(alpha:0.2)),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          size: 60,
                          color: _vibrantBlue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Smart Lost & Found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back! Please login to continue',
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha:0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // EMAIL FIELD
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('Email', Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!value.contains('@')) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // PASSWORD FIELD
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: _textGrey,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: _vibrantBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // LOGIN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _vibrantBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                    shadowColor: _vibrantBlue.withValues(alpha:0.4),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // SIGNUP LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: _textGrey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupScreen()),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: _vibrantBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE INPUT DECORATION ---
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textGrey, fontSize: 14),
      prefixIcon: Icon(icon, color: _vibrantBlue, size: 20),
      filled: true,
      fillColor: _bgDeep.withValues(alpha:0.4),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha:0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _vibrantBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}