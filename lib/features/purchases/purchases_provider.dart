import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/purchase_model.dart';

class PurchasesNotifier extends StateNotifier<List<PurchaseItem>> {
  static const String _storageKey = 'archpharma_purchases_db';

  PurchasesNotifier() : super([]) {
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded
            .map((item) => PurchaseItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      }
    } catch (_) {}

    // First run on fresh device: start clean with 0 purchases
    state = [];
    await _saveToStorage(state);
  }

  Future<void> _saveToStorage(List<PurchaseItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((p) => p.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> addPurchase(PurchaseItem purchase) async {
    final list = List<PurchaseItem>.from(state);
    list.removeWhere((p) => p.orderNo == purchase.orderNo);
    list.insert(0, purchase);
    state = list;
    await _saveToStorage(list);
  }

  Future<void> deletePurchase(String orderNo) async {
    final list = List<PurchaseItem>.from(state)..removeWhere((p) => p.orderNo == orderNo);
    state = list;
    await _saveToStorage(list);
  }

  Future<void> clearAllPurchases() async {
    state = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode([]));
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    state = [];
    await _saveToStorage(state);
  }
}

final purchasesProvider = StateNotifierProvider<PurchasesNotifier, List<PurchaseItem>>((ref) {
  return PurchasesNotifier();
});
