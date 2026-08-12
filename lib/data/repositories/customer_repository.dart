import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';

abstract class CustomerRepository {
  Future<List<CustomerItem>> getCustomers();
  Future<void> addCustomer(CustomerItem customer);
  Future<void> updateCustomer(CustomerItem customer);
  Future<void> deleteCustomer(String id);
  Future<void> clearAll();
  Future<void> resetToDefaults();
}

class CustomerRepositoryImpl implements CustomerRepository {
  static const String _storageKey = 'archpharma_customers_db';

  List<CustomerItem>? _cachedCustomers;

  Future<void> _saveToStorage(List<CustomerItem> items) async {
    _cachedCustomers = List.from(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  @override
  Future<List<CustomerItem>> getCustomers() async {
    if (_cachedCustomers != null) {
      return List.from(_cachedCustomers!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _cachedCustomers = decoded
            .map((item) => CustomerItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return List.from(_cachedCustomers!);
      }
    } catch (_) {}

    // First run on fresh device: start clean with 0 customers
    _cachedCustomers = [];
    await _saveToStorage(_cachedCustomers!);
    return List.from(_cachedCustomers!);
  }

  @override
  Future<void> addCustomer(CustomerItem customer) async {
    final list = await getCustomers();
    list.removeWhere((c) => c.id == customer.id);
    list.insert(0, customer);
    await _saveToStorage(list);
  }

  @override
  Future<void> updateCustomer(CustomerItem customer) async {
    final list = await getCustomers();
    final index = list.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      list[index] = customer;
    } else {
      list.insert(0, customer);
    }
    await _saveToStorage(list);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final list = await getCustomers();
    list.removeWhere((c) => c.id == id);
    await _saveToStorage(list);
  }

  @override
  Future<void> clearAll() async {
    _cachedCustomers = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode([]));
    } catch (_) {}
  }

  @override
  Future<void> resetToDefaults() async {
    _cachedCustomers = [];
    await _saveToStorage(_cachedCustomers!);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl();
});
