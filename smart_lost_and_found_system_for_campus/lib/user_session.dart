import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  // --- Session Data ---
  static String name = "Guest User";
  static String email = "";
  static String phone = "";
  static String studentId = "";
  static String role = "Student";
  static String photoUrl = "";
  static Uint8List? profileImageBytes;

  // --- Settings ---
  static bool pushNotifications = true;
  static bool emailAlerts = true;
  static bool showPhoneToFinders = false;
  static bool isDarkMode = true;
  static String language = "English";

  // --- Token Logic with Permanent Storage ---
  static String? _token;

  // ✅ Getter for token
  static String? get token => _token;

  // ✅ Setter for token: Automatically saves to disk when changed
  static set token(String? value) {
    _token = value;
    _saveToDisk('django_token', value);
  }

  // ✅ Initialize Session: Call this in main.dart before runApp()
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('django_token');
    email = prefs.getString('user_email') ?? "";
    name = prefs.getString('user_name') ?? "Guest User";
    photoUrl = prefs.getString('user_photo') ?? "";

    print("📂 Session Restored. Token: $_token, User: $email");
  }

  // ✅ Helper to save strings to SharedPreferences
  static void _saveToDisk(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      prefs.remove(key);
    } else {
      prefs.setString(key, value);
    }
  }

  // ✅ Updated Logout: Clears both variables and disk storage
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Wipe everything from disk

    // Reset variables
    _token = null;
    name = "Guest User";
    email = "";
    phone = "";
    studentId = "";
    role = "Student";
    photoUrl = "";
    profileImageBytes = null;
    pushNotifications = true;
    emailAlerts = true;
    showPhoneToFinders = false;
    isDarkMode = true;
    language = "English";

    print("🔒 User logged out and session cleared.");
  }

  // ✅ Helper to save user profile info permanently
  static void storeProfile(String uName, String uEmail, String uPhoto) {
    name = uName;
    email = uEmail;
    photoUrl = uPhoto;
    _saveToDisk('user_name', uName);
    _saveToDisk('user_email', uEmail);
    _saveToDisk('user_photo', uPhoto);
  }
}