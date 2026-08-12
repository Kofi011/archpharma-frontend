import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

abstract class ProductRepository {
  Future<List<ProductItem>> getProducts();
  Future<void> addProduct(ProductItem product);
  Future<void> updateProduct(ProductItem product);
  Future<void> deleteProduct(String productId);
  Future<void> clearAll();
  Future<void> resetToDefaults();
}

class ProductRepositoryImpl implements ProductRepository {
  static const String _storageKey = 'archpharma_products_db';

  List<ProductItem>? _cachedProducts;

  Future<void> _saveToStorage(List<ProductItem> items) async {
    _cachedProducts = List.from(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((p) => p.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  @override
  Future<List<ProductItem>> getProducts() async {
    if (_cachedProducts != null) {
      return List.from(_cachedProducts!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _cachedProducts = decoded
            .map((item) => ProductItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return List.from(_cachedProducts!);
      }
    } catch (_) {}

    // First run on fresh device: start clean with 0 products
    _cachedProducts = [];
    await _saveToStorage(_cachedProducts!);
    return List.from(_cachedProducts!);
  }

  @override
  Future<void> addProduct(ProductItem product) async {
    final list = await getProducts();
    list.removeWhere((p) => p.id == product.id);
    list.insert(0, product);
    await _saveToStorage(list);
  }

  @override
  Future<void> updateProduct(ProductItem product) async {
    final list = await getProducts();
    final index = list.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      list[index] = product;
    } else {
      list.insert(0, product);
    }
    await _saveToStorage(list);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final list = await getProducts();
    list.removeWhere((p) => p.id == productId);
    await _saveToStorage(list);
  }

  @override
  Future<void> clearAll() async {
    _cachedProducts = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode([]));
    } catch (_) {}
  }

  @override
  Future<void> resetToDefaults() async {
    _cachedProducts = [];
    await _saveToStorage(_cachedProducts!);
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl();
});
