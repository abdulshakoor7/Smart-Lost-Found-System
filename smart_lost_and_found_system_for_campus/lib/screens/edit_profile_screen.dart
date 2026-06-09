import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../user_session.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- FIGMA THEME COLORS ---
  final Color _bgDeep = const Color(0xFF0F172A);
  final Color _cardBg = const Color(0xFF1E293B);
  final Color _vibrantBlue = const Color(0xFF3B82F6);
  final Color _textGrey = const Color(0xFF94A3B8);

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _idController;

  Uint8List? _tempImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: UserSession.name);
    _phoneController = TextEditingController(text: UserSession.phone);
    _idController = TextEditingController(text: UserSession.studentId);
    _tempImageBytes = UserSession.profileImageBytes;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.first.bytes != null) {
      setState(() {
        _tempImageBytes = result.files.first.bytes;
      });
    }
  }

  // --- THE GENIUS FIX: STEP-BY-STEP SAVE (Logic Preserved) ---
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      debugPrint("🚀 Step 1: Getting Current User...");
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String finalPhotoUrl = UserSession.photoUrl;

      // 1. UPLOAD TO STORAGE (Logic Preserved)
      if (_tempImageBytes != null && _tempImageBytes != UserSession.profileImageBytes) {
        debugPrint("🚀 Step 2: Uploading Image...");
        Reference ref = FirebaseStorage.instance.ref().child('profile_pics').child('$uid.jpg');
        SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = ref.putData(_tempImageBytes!, metadata);
        TaskSnapshot snapshot = await uploadTask;
        finalPhotoUrl = await snapshot.ref.getDownloadURL();
      }

      debugPrint("🚀 Step 3: Saving to Firestore using Merge logic...");

      // Saving to Firestore (Logic Preserved)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'student_id': _idController.text.trim(),
        'photo_url': finalPhotoUrl,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("🚀 Step 4: Updating Local Session...");
      UserSession.name = _nameController.text.trim();
      UserSession.phone = _phoneController.text.trim();
      UserSession.studentId = _idController.text.trim();
      UserSession.photoUrl = finalPhotoUrl;
      UserSession.profileImageBytes = _tempImageBytes;

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Saved Successfully!"), backgroundColor: Colors.green)
      );

      Navigator.pop(context, true);

    } catch (e) {
      debugPrint("❌ CRITICAL ERROR AT SAVE: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Technical Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep, // Updated Background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Figma style transparent
        elevation: 0,
        centerTitle: true,
        title: const Text(
            "Edit Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // PROFILE PIC SECTION
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _vibrantBlue.withValues(alpha:0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: _cardBg,
                      backgroundImage: _tempImageBytes != null
                          ? MemoryImage(_tempImageBytes!)
                          : (UserSession.photoUrl.isNotEmpty ? NetworkImage(UserSession.photoUrl) : null) as ImageProvider?,
                      child: (_tempImageBytes == null && UserSession.photoUrl.isEmpty)
                          ? Icon(Icons.person, size: 55, color: _textGrey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _vibrantBlue,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // FORM SECTION
            _buildInput("FULL NAME", _nameController, Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildInput("PHONE NUMBER", _phoneController, Icons.phone_android_outlined),
            const SizedBox(height: 20),
            _buildInput("STUDENT ROLL NO", _idController, Icons.badge_outlined),

            const SizedBox(height: 50),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: _vibrantBlue.withValues(alpha:0.4),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE FIGMA INPUT FIELD ---
  Widget _buildInput(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
              label,
              style: TextStyle(color: _vibrantBlue, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)
          ),
        ),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _textGrey, size: 20),
            filled: true,
            fillColor: _cardBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha:0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _vibrantBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}