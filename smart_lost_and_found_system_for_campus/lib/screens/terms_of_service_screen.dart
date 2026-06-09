import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  final Color _bg = const Color(0xFFF9FAFB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Terms of Service", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to the Smart Lost & Found System",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            Text("Last updated: January 2026", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),

            _buildSection(
                "1. Purpose of the Application",
                "The Smart Lost and Found System is a platform designed exclusively for the students and staff of the University of Gujrat. Its purpose is to facilitate the reporting, matching, and returning of lost physical assets on campus."
            ),

            _buildSection(
                "2. User Accounts & Security",
                "• You must register using a valid @uog.edu.pk email address.\n"
                    "• You are responsible for maintaining the confidentiality of your login credentials.\n"
                    "• Any fraudulent claims or misuse of the platform will result in immediate suspension and disciplinary action by the University Administration."
            ),

            _buildSection(
                "3. Artificial Intelligence & Data Processing",
                "By uploading images to the platform, you grant the system permission to process these images using Artificial Intelligence (TensorFlow) for the sole purpose of feature extraction and category matching. We do not use your images to train external commercial models."
            ),

            _buildSection(
                "4. Privacy & Communication",
                "• Your personal phone number is hidden by default.\n"
                    "• Communication between the finder and the loser must occur through the in-app chat system to ensure privacy.\n"
                    "• Administrators have the right to review chat logs if a dispute or harassment claim is filed."
            ),

            _buildSection(
                "5. Claim Verification",
                "To successfully claim a found item, you must provide valid proof of ownership (e.g., serial number, specific physical marks, or lock screen details). The final decision to release an item rests with the Security Administrator."
            ),

            _buildSection(
                "6. Limitation of Liability",
                "The University of Gujrat and the developers of this application are not legally responsible for any permanently lost, stolen, or damaged items. This platform is a tool to assist in recovery, not a guarantee of restitution."
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha:0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "By continuing to use this application, you agree to abide by these terms and the University Code of Conduct.",
                      style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5)),
        ],
      ),
    );
  }
}