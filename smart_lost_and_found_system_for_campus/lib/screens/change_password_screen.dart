import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController(); // Added Confirm Controller

  bool _isLoading = false;

  // Visibility Toggles
  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  // --- FIGMA THEME COLORS ---
  final Color _bgDeep = const Color(0xFF0F172A);
  final Color _cardBg = const Color(0xFF1E293B);
  final Color _vibrantBlue = const Color(0xFF3B82F6);
  final Color _textGrey = const Color(0xFF94A3B8);

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // --- SECURE PASSWORD UPDATE LOGIC ---
  Future<void> _changePassword() async {
    // 1. Basic Form Validation
    if (!_formKey.currentState!.validate()) return;

    // 2. Logic Check: Do new passwords match?
    if (_newController.text.trim() != _confirmController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 3. Re-authenticate user (Security Requirement)
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // 4. Perform Update
      await user.updatePassword(_newController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password Updated Successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message = "Update Failed";
      if (e.code == 'wrong-password') {
        message = "The current password you entered is incorrect.";
      } else if (e.code == 'weak-password') {
        message = "The new password is too weak.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
            "Security",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _vibrantBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded, size: 40, color: _vibrantBlue),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  "Change Password",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Update your account security credentials",
                  style: TextStyle(color: _textGrey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 48),

              // --- INPUT FIELDS ---
              _buildLabel("CURRENT PASSWORD"),
              _buildPasswordField(_currentController, _isCurrentVisible, (v) => setState(() => _isCurrentVisible = v)),

              const SizedBox(height: 24),
              _buildLabel("NEW PASSWORD"),
              _buildPasswordField(_newController, _isNewVisible, (v) => setState(() => _isNewVisible = v)),

              const SizedBox(height: 24),
              _buildLabel("CONFIRM NEW PASSWORD"),
              _buildPasswordField(_confirmController, _isConfirmVisible, (v) => setState(() => _isConfirmVisible = v)),

              const SizedBox(height: 48),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: _vibrantBlue.withValues(alpha: 0.4),
                  ),
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Update Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
          text,
          style: TextStyle(color: _vibrantBlue, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, bool isVisible, Function(bool) toggle) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.key_rounded, color: _textGrey, size: 20),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: _textGrey, size: 20),
          onPressed: () => toggle(!isVisible),
        ),
        filled: true,
        fillColor: _cardBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _vibrantBlue, width: 1.5),
        ),
      ),
      validator: (val) => val!.length < 6 ? "Must be at least 6 chars" : null,
    );
  }
}