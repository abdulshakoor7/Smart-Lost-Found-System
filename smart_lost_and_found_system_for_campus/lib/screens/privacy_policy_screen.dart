import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          "At UOG Smart Lost & Found, your privacy is our priority.\n\n"
              "1. Data Collection: We store your university email, roll number, and photos of items reported to facilitate recovery.\n\n"
              "2. AI Processing: Photos are analyzed using TensorFlow for feature extraction. These images are not used for any other purpose.\n\n"
              "3. Communication: Your personal phone number is masked. Chatting occurs securely through our Firebase-encrypted system.\n\n"
              "4. Data Rights: You may delete your account and all associated data at any time via the Profile settings.",
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
        ),
      ),
    );
  }
}