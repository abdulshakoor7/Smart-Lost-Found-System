import 'dart:io'; // ✅ Added for File operations
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // ✅ Added for Cache clearing
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is imported
import 'dart:convert';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../user_session.dart' show UserSession;
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color _accentBlue = const Color(0xFF3B82F6);

  // ✅ LOGIC: Sync Privacy Setting with Backend
  Future<void> _handlePhonePrivacySync(bool value, AppState appState) async {
    // ✅ PHASE 3: THE PRINT STATEMENT (Add it here)
    debugPrint("🔍 DEBUG: Current User Token is: ${UserSession.token}");

    if (UserSession.token == null || UserSession.token!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Session expired. Please log in again.")),
        );
      }
      return;
    }

    appState.updateSetting('phone', value);

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/items/update_privacy/"),
        headers: {
          ...ApiService.headers,
          // ✅ HANDLE THE PREFIX: Change 'Bearer' to 'Token' if standard Django Auth is used
          "Authorization": "Token ${UserSession.token}",

        },
        body: jsonEncode({"show_phone": value}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud sync: Active"), backgroundColor: Colors.green),
        );
      } else {
        debugPrint("❌ Server rejected with: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud sync failed.")),
        );
      }
    } catch (e) {
      debugPrint("❌ Network Error: $e");
    }
  }

  // ✅ LOGIC: Physical Cache Clearing

  Future<void> _clearCache() async {
    try {
      // ✅ THE GENIUS FIX: SharedPreferences works on BOTH Web and Mobile.
      // On Web, it automatically clears the Browser's LocalStorage.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!kIsWeb) {
        // Mobile-only folder deletion
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("🗑️ Cache & Session Cleared Successfully"),
            backgroundColor: Colors.blue
        ),
      );
    } catch (e) {
      debugPrint("❌ Cache Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- 1. NOTIFICATIONS ---
          _buildSectionHeader("Notifications"),

          // ✅ Push Notifications Toggle
          _buildSwitchTile(Icons.notifications_active_outlined, "Push Notifications",
              appState.pushNotifications, (v) {
                appState.updateSetting('push', v);
                // Providing immediate feedback as requested
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Cloud Sync: Active"),
                        backgroundColor: Colors.green,
                        duration: Duration(milliseconds: 800)
                    )
                );
              }),

          // ✅ Email Match Alerts Toggle
          _buildSwitchTile(Icons.alternate_email_rounded, "Email Match Alerts",
              appState.emailAlerts, (v) {
                appState.updateSetting('email', v);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Email Alerts preferences updated"),
                        duration: Duration(milliseconds: 800)
                    )
                );
              }),

          const SizedBox(height: 32),

          // --- 2. PRIVACY & SECURITY ---
          _buildSectionHeader("Privacy & Security"),

          // ✅ Privacy Sync Toggle
          _buildSwitchTile(Icons.phone_iphone_rounded, "Show Phone to Finders",
              appState.showPhone, (v) => _handlePhonePrivacySync(v, appState)),

          _buildNavTile(Icons.security_outlined, "App Permissions", "Camera & Location", () async {
            await appState.requestPermissions();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Permissions Synchronized with System"), backgroundColor: Colors.blue)
              );
            }
          }),

          const SizedBox(height: 32),

          // --- 3. SYSTEM PREFERENCES ---
          _buildSectionHeader("System Preferences"),

          _buildSwitchTile(Icons.dark_mode_rounded, "Dark Mode",
              appState.themeMode == ThemeMode.dark, (v) => appState.toggleTheme(v)),

          _buildNavTile(Icons.info_outline_rounded, "About SmartFind", "v1.0.5 Patch", () {
            _showAboutAppDialog(context);
          }),

          // ✅ Functional Clear Cache Button
          _buildNavTile(Icons.cleaning_services_rounded, "Clear App Cache", "Free up space", () => _clearCache()),

          const SizedBox(height: 40),
          const Center(child: Text("Designed for UOG Campus", style: TextStyle(color: Colors.grey, fontSize: 11))),
        ],
      ),
    );
  }

  // --- ABOUT DIALOG UI ---
  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentBlue.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_rounded, size: 50, color: _accentBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              "SmartFind",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Version 1.0.5 (Build 2024.1)",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10, thickness: 1),
            const SizedBox(height: 15),
            const Text(
              "The official Lost & Found solution for UOG Campus. Helping students reconnect with their belongings through AI and real-time tracking.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 25),
            const Text(
              "© 2024 UOG Tech Team",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(), style: TextStyle(color: _accentBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, Function(bool) onChanged) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: _accentBlue),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        value: value,
        activeColor: Colors.white,
        activeTrackColor: _accentBlue,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavTile(IconData icon, String title, String sub, VoidCallback tap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: tap,
        leading: Icon(icon, color: _accentBlue),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}