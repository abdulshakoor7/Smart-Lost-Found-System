import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../user_session.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // --- FORM CONTROLLERS ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // --- ANIMATIONS ---
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // --- THEME COLORS (Figma Standard) ---
  final Color _bgDeep = const Color(0xFF0F172A);
  final Color _cardBg = const Color(0xFF1E293B);
  final Color _vibrantBlue = const Color(0xFF3B82F6);
  final Color _textGrey = const Color(0xFF94A3B8);

  // Google Sign In Instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '199666906527-hle9qh03tltfkho2v43gk97vbt6j758v.apps.googleusercontent.com',
    scopes: ['email'],
  );

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
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC 1: STANDARD EMAIL SIGNUP ---
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        debugPrint("🚀 Initializing Firebase Auth Registration...");

        // 1. Create User in Firebase Auth
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Send Verification Email (Security Requirement)
        await userCredential.user!.sendEmailVerification();

        // 3. Sync Data to Cloud Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': 'student',
          'is_verified': false,
          'created_at': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSuccessDialog(_emailController.text.trim());
        }
      } catch (e) {
        debugPrint("❌ Registration Error: $e");
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- LOGIC 2: GOOGLE SIGNUP (RESTRICTED TO UOG) ---
  Future<void> _handleGoogleSignup() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // --- SECURITY CHECK: DOMAIN RESTRICTION ---
        String userEmail = googleUser.email.toLowerCase();
        if (!userEmail.endsWith('@uog.edu.pk')) {
          await _googleSignIn.signOut();
          if (mounted) {
            _showErrorSnackBar(
                'Access Denied: Only @uog.edu.pk accounts allowed.');
          }
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);

        // Sync to Firestore if it's a new user
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'name': googleUser.displayName,
            'email': userEmail,
            'role': 'student',
            'photo_url': googleUser.photoUrl,
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        // Set Real-Time Session Data
        UserSession.email = userEmail;
        UserSession.name = googleUser.displayName ?? "Student";

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Google Sign-in Successful!'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Google Sign In Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI HELPERS ---
  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Verify Email",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            "A verification link has been sent to $email. Please verify your account before logging in.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _vibrantBlue),
            child: const Text("I Understand",
                style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgDeep, const Color(0xFF1E1B4B)],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Branding Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _vibrantBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _vibrantBlue.withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.person_add_rounded,
                            size: 50, color: _vibrantBlue),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1),
                      ),
                      Text(
                        'Join the UOG Campus Community',
                        style: TextStyle(color: _textGrey, fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      // Signup Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20)
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(_nameController, 'Full Name',
                                  Icons.person_outline),
                              const SizedBox(height: 18),
                              _buildTextField(_studentIdController,
                                  'Student Roll No', Icons.badge_outlined),
                              const SizedBox(height: 18),
                              _buildTextField(_phoneController, 'Phone Number',
                                  Icons.phone_android_outlined,
                                  type: TextInputType.phone),
                              const SizedBox(height: 18),

                              // UOG EMAIL INPUT
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                    'UOG Email (@uog.edu.pk)',
                                    Icons.email_outlined),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!value
                                      .toLowerCase()
                                      .endsWith('@uog.edu.pk')) {
                                    return 'Use official UOG email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // PASSWORD INPUT
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                        'Password', Icons.lock_outline)
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: _textGrey,
                                        size: 20),
                                    onPressed: () => setState(() =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible),
                                  ),
                                ),
                                validator: (value) => value!.length < 6
                                    ? 'Password too short'
                                    : null,
                              ),

                              const SizedBox(height: 32),

                              // SUBMIT BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _vibrantBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 8,
                                    shadowColor:
                                        _vibrantBlue.withValues(alpha: 0.4),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text('Sign Up',
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold)),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: Colors.white
                                              .withValues(alpha: 0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text("OR",
                                        style: TextStyle(
                                            color: _textGrey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: Colors.white
                                              .withValues(alpha: 0.1))),
                                ],
                              ),

                              const SizedBox(height: 28),

                              // GOOGLE BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _handleGoogleSignup,
                                  icon: Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_\"G\"_Logo.svg',
                                      height: 20,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.g_mobiledata,
                                          color: Colors.red)),
                                  label: const Text("Sign up with Google",
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.1)),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.02),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account? ',
                              style: TextStyle(color: _textGrey)),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Login',
                                style: TextStyle(
                                    color: _vibrantBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
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
      fillColor: _bgDeep.withValues(alpha: 0.4),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _vibrantBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
      validator: (value) => value!.isEmpty ? '$label is required' : null,
    );
  }
}
