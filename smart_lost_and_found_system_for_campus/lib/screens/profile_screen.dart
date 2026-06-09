import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../user_session.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'my_items_screen.dart';
import 'settings_screen.dart';

// --- NEW IMPORTS ---
import 'privacy_policy_screen.dart';
import 'help_support_screen.dart'; // We will use this for Help & Bug Report

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- THEME COLORS ---
  final Color _bg = const Color(0xFF0F172A);
  final Color _cardBg = const Color(0xFF1E293B);
  final Color _accentBlue = const Color(0xFF3B82F6);
  final Color _textGrey = const Color(0xFF94A3B8);

  // --- REAL-TIME STATS ---
  int _reportedCount = 0;
  int _recoveredCount = 0;
  int _activeCount = 0;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateUserStats();
  }

  // --- GENIUS STATS LOGIC ---
  Future<void> _calculateUserStats() async {
    try {
      final allItems = await ApiService.fetchItems();
      String myEmail = UserSession.email.trim().toLowerCase();

      if (mounted) {
        setState(() {
          // 1. Total Reported by this user
          var myItems = allItems.where((i) => (i['user_email'] ?? '').toString().toLowerCase() == myEmail).toList();
          _reportedCount = myItems.length;

          // 2. Recovered (Status is VERIFIED or CLAIMED)
          _recoveredCount = myItems.where((i) => ['VERIFIED', 'CLAIMED'].contains(i['status'])).length;

          // 3. Active (Still in the loop)
          _activeCount = myItems.where((i) => ['PENDING', 'PUBLISHED', 'MATCH_FOUND', 'CLAIM_REQUESTED'].contains(i['status'])).length;

          _isStatsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: _calculateUserStats,
        color: _accentBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // --- 1. USER IDENTITY SECTION ---
              _buildUserHeader(),

              const SizedBox(height: 32),

              // --- 2. ACHIEVEMENT STATS (DYNAMIC) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildStatCard(_reportedCount.toString(), "Reported"),
                    const SizedBox(width: 12),
                    _buildStatCard(_recoveredCount.toString(), "Recovered"),
                    const SizedBox(width: 12),
                    _buildStatCard(_activeCount.toString(), "Active"),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- 3. MENU GROUPS ---
              _buildMenuSection("ACCOUNT Management", [
                _buildMenuItem(Icons.person_outline, "Edit Profile", () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (c) => const EditProfileScreen()));
                  _calculateUserStats(); // Refresh stats/profile on return
                }),
                _buildMenuItem(Icons.history_rounded, "My Activity History", () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const MyItemsScreen()));
                }),
                _buildMenuItem(Icons.vpn_key_outlined, "Security & Password", () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const ChangePasswordScreen()));
                }),
              ]),

              _buildMenuSection("SYSTEM", [
                _buildMenuItem(Icons.settings_outlined, "App Settings", () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
                }),
                _buildMenuItem(Icons.shield_outlined, "Privacy Policy", () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const PrivacyPolicyScreen()));
                }),
              ]),

              _buildMenuSection("SUPPORT", [
                _buildMenuItem(Icons.help_center_outlined, "Help Center", () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const HelpSupportScreen()));
                }),
                _buildMenuItem(Icons.bug_report_outlined, "Report a Bug", () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const HelpSupportScreen()));
                }),
              ]),

              const SizedBox(height: 32),

              // --- LOGOUT BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      UserSession.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text("Logout Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha:0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildUserHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: _accentBlue,
          child: CircleAvatar(
            radius: 52,
            backgroundColor: _bg,
            backgroundImage: UserSession.profileImageBytes != null
                ? MemoryImage(UserSession.profileImageBytes!)
                : (UserSession.photoUrl.isNotEmpty ? NetworkImage(UserSession.photoUrl) : null) as ImageProvider?,
            child: UserSession.profileImageBytes == null && UserSession.photoUrl.isEmpty
                ? Icon(Icons.person, size: 50, color: _textGrey) : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(UserSession.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(UserSession.email, style: TextStyle(color: _textGrey, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: _accentBlue.withValues(alpha:0.2), borderRadius: BorderRadius.circular(20)),
          child: Text("Roll No: ${UserSession.studentId}", style: TextStyle(color: _accentBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            _isStatsLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
                : Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: _textGrey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 12, top: 24),
          child: Text(title.toUpperCase(), style: TextStyle(color: _accentBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(20)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback tap) {
    return ListTile(
      onTap: tap,
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
    );
  }
}