import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/supplier_model.dart';

class SuppliersNotifier extends StateNotifier<List<SupplierItem>> {
  static const String _storageKey = 'archpharma_suppliers_db';

  SuppliersNotifier() : super([]) {
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded
            .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return;
      }
    } catch (_) {}

    // First run on fresh device: start clean with 0 suppliers
    state = [];
    await _saveToStorage(state);
  }

  Future<void> _saveToStorage(List<SupplierItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((s) => s.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> addSupplier(SupplierItem supplier) async {
    final list = List<SupplierItem>.from(state);
    list.removeWhere((s) => s.id == supplier.id);
    list.insert(0, supplier);
    state = list;
    await _saveToStorage(list);
  }

  Future<void> updateSupplier(SupplierItem supplier) async {
    final list = List<SupplierItem>.from(state);
    final index = list.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      list[index] = supplier;
    } else {
      list.insert(0, supplier);
    }
    state = list;
    await _saveToStorage(list);
  }

  Future<void> deleteSupplier(String id) async {
    final list = List<SupplierItem>.from(state)..removeWhere((s) => s.id == id);
    state = list;
    await _saveToStorage(list);
  }

  Future<void> clearAllSuppliers() async {
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

final suppliersProvider = StateNotifierProvider<SuppliersNotifier, List<SupplierItem>>((ref) {
  return SuppliersNotifier();
});
