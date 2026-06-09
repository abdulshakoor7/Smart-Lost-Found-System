import 'dart:convert';
import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../user_session.dart';

class ApiService {
  // --- 1. CONFIGURATION ---
  // ✅ FIX: Removed trailing space from the link to prevent URI parsing errors
  static const String activeNgrokLink = "https://ship-frugality-capsule.ngrok-free.dev";

  // ✅ GENIUS LOGIC: Separate Base URL (Root) from API URL (Endpoint root)
  // This prevents the "apiapi" duplicate path error while making image loading easier.
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000";
    } else {
      return activeNgrokLink.trim();
    }
  }

  static String get apiUrl => "$baseUrl/api";

  // --- 2. HEADER MANAGEMENT ---
  // ✅ This bypasses the Ngrok "browser warning" and sets JSON standards
  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "ngrok-skip-browser-warning": "69420",
  };

  // Helper to inject Authorization Token into headers
  static Map<String, String> _getAuthHeaders() {
    Map<String, String> authHeaders = Map.from(headers);
    if (UserSession.token != null && UserSession.token!.isNotEmpty) {
      authHeaders["Authorization"] = "Token ${UserSession.token}";
    }
    return authHeaders;
  }

  // --- 3. FETCH ALL ITEMS ---
  static Future<List<dynamic>> fetchItems() async {
    try {
      final requestUrl = "$apiUrl/items/";
      debugPrint("🚀 PRO-CHECK: Fetching items from $requestUrl");

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: _getAuthHeaders(), // Using synchronized auth headers
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("❌ Fetch Failure: HTTP ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Connection Protocol Error: $e");
      return [];
    }
  }

  // --- 4. FETCH NOTIFICATIONS ---
  static Future<List<dynamic>> fetchNotifications() async {
    try {
      String userEmail = UserSession.email?.trim().toLowerCase() ?? "";
      final response = await http.get(
        Uri.parse("$apiUrl/notifications/?email=$userEmail"),
        headers: _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("❌ API Error (Notifications): $e");
    }
    return [];
  }

  // --- 5. REPORT ITEM (Multipart Request) ---
  static Future<bool> reportItem({
    required Map<String, String> data,
    required List<PlatformFile> files,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$apiUrl/items/"));

      // Standardize headers for the Multipart stream
      request.headers.addAll({
        "ngrok-skip-browser-warning": "69420",
        if (UserSession.token != null) "Authorization": "Token ${UserSession.token}"
      });

      request.fields.addAll(data);
      request.fields['user_email'] = UserSession.email?.trim().toLowerCase() ?? "";

      for (int i = 0; i < files.length; i++) {
        String fieldName = (i == 0) ? 'image' : 'gallery';
        if (kIsWeb) {
          if (files[i].bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
                fieldName, files[i].bytes!, filename: files[i].name));
          }
        } else {
          if (files[i].path != null) {
            request.files.add(await http.MultipartFile.fromPath(fieldName, files[i].path!));
          }
        }
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);

      debugPrint("📤 Upload Status: ${response.statusCode}");
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ API Error (Report Item): $e");
      return false;
    }
  }

  // --- 6. SMART SEARCH ---
  static Future<List<dynamic>> smartSearch({String? query, Uint8List? imageBytes}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse("$apiUrl/items/smart_search/"));
      request.headers.addAll({"ngrok-skip-browser-warning": "69420"});

      if (query != null) request.fields['query'] = query;

      if (imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
            'image', imageBytes, filename: 'ai_search_query.jpg'));
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("❌ API Error (Smart Search): $e");
    }
    return [];
  }

  // --- 7. UPDATE ITEM STATUS ---
  static Future<bool> updateItemStatus(int id, String newStatus, {String? proofText}) async {
    try {
      Map<String, dynamic> bodyData = {'status': newStatus};
      if (proofText != null) bodyData['claim_proof'] = proofText;

      final response = await http.patch(
        Uri.parse("$apiUrl/items/$id/"),
        headers: _getAuthHeaders(),
        body: jsonEncode(bodyData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ API Error (Update Status): $e");
      return false;
    }
  }

  // --- 8. DELETE ITEM ---
  static Future<bool> deleteItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$apiUrl/items/$id/"),
        headers: _getAuthHeaders(),
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint("❌ API Error (Delete): $e");
      return false;
    }
  }

  // --- 9. ADMIN: BAN / UNBAN USER ---
  static Future<bool> toggleUserStatus(String userEmail, String action) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/items/manage_user/"),
        headers: _getAuthHeaders(),
        body: jsonEncode({
          'email': userEmail,
          'action': action,
          'admin_email': UserSession.email,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- 10. ADMIN: FETCH AUDIT LOGS ---
  static Future<List<dynamic>> fetchAuditLogs() async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/items/audit_logs/"),
        headers: _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("❌ API Error (Audit Logs): $e");
    }
    return [];
  }

  // --- 11. RAPID API: REVERSE GEOCODING ---
  static Future<String> getAddressFromRapidApi(double lat, double lng) async {
    try {
      final url = Uri.parse(
          "https://google-map-places.p.rapidapi.com/maps/api/geocode/json?latlng=$lat,$lng&language=en"
      );

      final response = await http.get(url, headers: {
        'x-rapidapi-key': "16bf7bd93dmsh0448b993c9a887fp1a7941jsnb98f5ffd5403",
        'x-rapidapi-host': "google-map-places.p.rapidapi.com",
        'Accept': "application/json"
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          String address = data['results'][0]['formatted_address'];
          return address.replaceAll(", Pakistan", "");
        }
      }
    } catch (e) {
      debugPrint("❌ RapidAPI Error: $e");
    }
    return "${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }

  // --- 12. HELPER: FORMAT IMAGE URL ---
  // ✅ LOGIC: Dynamically resolves the media host based on platform
  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return "";
    if (imageUrl.startsWith('http')) return imageUrl;

    // Use the dynamic root baseUrl
    String root = baseUrl;

    // Standardize the media path suffix
    String formattedPath = imageUrl;
    if (!formattedPath.contains('/media/')) {
      formattedPath = formattedPath.startsWith('/') ? "/media$formattedPath" : "/media/$formattedPath";
    } else {
      formattedPath = formattedPath.startsWith('/') ? formattedPath : "/$formattedPath";
    }

    return "$root$formattedPath";
  }

  // --- 13. NOTIFICATION MANAGEMENT ---
  static Future<void> markNotificationRead(int id) async {
    try {
      await http.patch(
        Uri.parse("$apiUrl/notifications/$id/mark_as_read/"),
        headers: _getAuthHeaders(),
      );
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }
}