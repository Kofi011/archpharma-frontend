import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'ArchPharma';
  static const String companyName = 'ARCH PHARMACY LTD.';
  static const String tagline = '(WHOLESALERS OF PRESCRIPTION DRUGS)';
  static const String contactPhones = '0596549541 / 0534340375';

  static const String logoAsset = 'assets/images/archpharma_logo.png';

  static String get apiBaseUrl {
    return 'https://archpharma-backend-production.up.railway.app/api/v1';
  }

  static bool get enableDebugLogs => !kReleaseMode;
}
