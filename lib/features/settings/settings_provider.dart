import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class AppSettings {
  final String companyName;
  final String tagline;
  final String phones;
  final String currency;
  final String printerType;
  final bool autoPrintOnSave;
  final double printCopiesCount;
  final bool preventZeroStockBilling;
  final double expiryAlertDays;
  final double minProfitMargin;
  final bool autoLockOverdueAccounts;
  final String agingThreshold;
  final String apiEndpoint;
  final String logoAsset;

  const AppSettings({
    required this.companyName,
    required this.tagline,
    required this.phones,
    required this.currency,
    required this.printerType,
    required this.autoPrintOnSave,
    required this.printCopiesCount,
    required this.preventZeroStockBilling,
    required this.expiryAlertDays,
    required this.minProfitMargin,
    required this.autoLockOverdueAccounts,
    required this.agingThreshold,
    required this.apiEndpoint,
    required this.logoAsset,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      companyName: AppConstants.companyName,
      tagline: AppConstants.tagline,
      phones: AppConstants.contactPhones,
      currency: 'GHS',
      printerType: 'POS Thermal (80mm)',
      autoPrintOnSave: true,
      printCopiesCount: 2.0,
      preventZeroStockBilling: true,
      expiryAlertDays: 90.0,
      minProfitMargin: 10.0,
      autoLockOverdueAccounts: true,
      agingThreshold: '120',
      apiEndpoint: AppConstants.apiBaseUrl,
      logoAsset: AppConstants.logoAsset,
    );
  }

  AppSettings copyWith({
    String? companyName,
    String? tagline,
    String? phones,
    String? currency,
    String? printerType,
    bool? autoPrintOnSave,
    double? printCopiesCount,
    bool? preventZeroStockBilling,
    double? expiryAlertDays,
    double? minProfitMargin,
    bool? autoLockOverdueAccounts,
    String? agingThreshold,
    String? apiEndpoint,
    String? logoAsset,
  }) {
    return AppSettings(
      companyName: companyName ?? this.companyName,
      tagline: tagline ?? this.tagline,
      phones: phones ?? this.phones,
      currency: currency ?? this.currency,
      printerType: printerType ?? this.printerType,
      autoPrintOnSave: autoPrintOnSave ?? this.autoPrintOnSave,
      printCopiesCount: printCopiesCount ?? this.printCopiesCount,
      preventZeroStockBilling: preventZeroStockBilling ?? this.preventZeroStockBilling,
      expiryAlertDays: expiryAlertDays ?? this.expiryAlertDays,
      minProfitMargin: minProfitMargin ?? this.minProfitMargin,
      autoLockOverdueAccounts: autoLockOverdueAccounts ?? this.autoLockOverdueAccounts,
      agingThreshold: agingThreshold ?? this.agingThreshold,
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      logoAsset: logoAsset ?? this.logoAsset,
    );
  }

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'tagline': tagline,
    'phones': phones,
    'currency': currency,
    'printerType': printerType,
    'autoPrintOnSave': autoPrintOnSave,
    'printCopiesCount': printCopiesCount,
    'preventZeroStockBilling': preventZeroStockBilling,
    'expiryAlertDays': expiryAlertDays,
    'minProfitMargin': minProfitMargin,
    'autoLockOverdueAccounts': autoLockOverdueAccounts,
    'agingThreshold': agingThreshold,
    'apiEndpoint': apiEndpoint,
    'logoAsset': logoAsset,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    companyName: json['companyName'] as String? ?? AppConstants.companyName,
    tagline: json['tagline'] as String? ?? AppConstants.tagline,
    phones: json['phones'] as String? ?? AppConstants.contactPhones,
    currency: json['currency'] as String? ?? 'GHS',
    printerType: json['printerType'] as String? ?? 'POS Thermal (80mm)',
    autoPrintOnSave: json['autoPrintOnSave'] as bool? ?? true,
    printCopiesCount: (json['printCopiesCount'] as num?)?.toDouble() ?? 2.0,
    preventZeroStockBilling: json['preventZeroStockBilling'] as bool? ?? true,
    expiryAlertDays: (json['expiryAlertDays'] as num?)?.toDouble() ?? 90.0,
    minProfitMargin: (json['minProfitMargin'] as num?)?.toDouble() ?? 10.0,
    autoLockOverdueAccounts: json['autoLockOverdueAccounts'] as bool? ?? true,
    agingThreshold: json['agingThreshold'] as String? ?? '120',
    apiEndpoint: json['apiEndpoint'] as String? ?? AppConstants.apiBaseUrl,
    logoAsset: json['logoAsset'] as String? ?? AppConstants.logoAsset,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _prefsKey = 'archpharma_app_settings';

  SettingsNotifier() : super(AppSettings.defaultSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson) as Map<String, dynamic>;
        state = AppSettings.fromJson(decoded);
      }
    } catch (_) {
      // Fallback to default state
    }
  }

  Future<void> saveSettings(AppSettings newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(newSettings.toJson()));
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    final defaults = AppSettings.defaultSettings();
    state = defaults;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
