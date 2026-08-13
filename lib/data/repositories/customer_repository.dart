import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasource/api_client.dart';
import '../../features/auth/auth_provider.dart';
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
  final ApiClient? _apiClient;

  CustomerRepositoryImpl([this._apiClient]);

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
    // 1. Fetch fresh data from cloud API if online
    if (_apiClient != null) {
      try {
        final res = await _apiClient!.dio.get('/customers');
        if (res.statusCode == 200 && res.data is List) {
          final cloudList = (res.data as List).map((json) {
            final map = json as Map<String, dynamic>;
            return CustomerItem(
              id: map['id']?.toString() ?? '',
              businessName: map['name']?.toString() ?? map['businessName']?.toString() ?? '',
              contactPerson: map['contactPerson']?.toString() ?? '',
              phone: map['phone']?.toString() ?? '',
              email: map['email']?.toString() ?? '',
              address: map['address']?.toString() ?? '',
              creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0.0,
              outstandingBalance: (map['outstandingBalance'] as num?)?.toDouble() ?? (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
              status: map['status']?.toString() ?? 'active',
            );
          }).toList();
          await _saveToStorage(cloudList);
          return List.from(cloudList);
        }
      } catch (_) {}
    }

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

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.post('/customers', data: {
          'id': customer.id,
          'name': customer.businessName,
          'contactPerson': customer.contactPerson,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'creditLimit': customer.creditLimit,
        });
      } catch (_) {}
    }
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

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.put('/customers/${customer.id}', data: {
          'name': customer.businessName,
          'contactPerson': customer.contactPerson,
          'phone': customer.phone,
          'email': customer.email,
          'address': customer.address,
          'creditLimit': customer.creditLimit,
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final list = await getCustomers();
    list.removeWhere((c) => c.id == id);
    await _saveToStorage(list);

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.delete('/customers/$id');
      } catch (_) {}
    }
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
  final apiClient = ref.watch(apiClientProvider);
  return CustomerRepositoryImpl(apiClient);
});
