import 'package:flutter/foundation.dart';

class AppConfig {
  // Use AWS IP for both Web and Mobile during production testing
  static const String awsIp = "http://13.61.25.232";

  // Local laptop IP for ultra-fast local development (Hot Reload)
  static const String localIp = "http://10.20.6.33:8000";

  static String get baseUrl {
    // If you are running 'flutter run', it uses localIp
    // If you are building the final APK, it uses awsIp
    if (kDebugMode) {
      return localIp;
    } else {
      return awsIp;
    }
  }
}