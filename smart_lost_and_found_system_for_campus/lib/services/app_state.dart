import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart'; // Added for permissions

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _showPhone = false;
  bool _pushNotifications = true;
  bool _emailAlerts = true;

  ThemeMode get themeMode => _themeMode;
  bool get showPhone => _showPhone;
  bool get pushNotifications => _pushNotifications;
  bool get emailAlerts => _emailAlerts;

  // --- 1. GLOBAL THEME ---
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // This signals EVERY screen to repaint
  }

  // --- 2. PERMISSION LOGIC ---
  Future<void> requestPermissions() async {
    // Requesting Camera and Location in real-time
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    debugPrint("Camera: ${statuses[Permission.camera]}, Location: ${statuses[Permission.location]}");
  }

  // --- 3. INDEPENDENT SETTERS (Optional helpers for UI) ---
  void setPush(bool val) => updateSetting('push', val);
  void setEmail(bool val) => updateSetting('email', val);
  void setShowPhone(bool val) => updateSetting('phone', val);

  // --- 4. REAL-TIME CLOUD SYNC ---
  Future<void> updateSetting(String key, bool value) async {
    // Update local state immediately for UI responsiveness
    if (key == 'phone') _showPhone = value;
    if (key == 'email') _emailAlerts = value;
    if (key == 'push') _pushNotifications = value;
    notifyListeners();

    // Sync with Firebase
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'settings.$key': value,
        });
      }
    } catch (e) {
      debugPrint("Firebase Sync Error: $e");
    }
  }
}