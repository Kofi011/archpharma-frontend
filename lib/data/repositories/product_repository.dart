import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasource/api_client.dart';
import '../../features/auth/auth_provider.dart';
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
  final ApiClient? _apiClient;

  ProductRepositoryImpl([this._apiClient]);

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
    // 1. Fetch fresh data from cloud API if online
    if (_apiClient != null) {
      try {
        final res = await _apiClient!.dio.get('/products');
        if (res.statusCode == 200 && res.data is List) {
          final List<ProductItem> cloudList = (res.data as List).map<ProductItem>((json) {
            final map = json as Map<String, dynamic>;
            return ProductItem(
              id: map['id']?.toString() ?? '',
              barcode: map['barcode']?.toString() ?? '',
              productName: map['name']?.toString() ?? map['productName']?.toString() ?? '',
              genericName: map['genericName']?.toString() ?? '',
              brandName: map['brandName']?.toString() ?? '',
              category: map['category']?.toString() ?? 'General',
              manufacturer: map['manufacturer']?.toString() ?? '',
              costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
              sellingPrice: (map['unitPrice'] as num?)?.toDouble() ?? (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
              reorderLevel: (map['reorderLevel'] as num?)?.toInt() ?? 10,
              status: map['status']?.toString() ?? 'active',
              currentStock: (map['stock'] as num?)?.toInt() ?? (map['currentStock'] as num?)?.toInt() ?? 0,
            );
          }).toList();
          await _saveToStorage(cloudList);
          return List.from(cloudList);
        }
      } catch (_) {
        // Fallback to local offline cache
      }
    }

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

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.post('/products', data: {
          'id': product.id,
          'name': product.productName,
          'barcode': product.barcode,
          'category': product.category,
          'unitPrice': product.sellingPrice,
          'costPrice': product.costPrice,
          'stock': product.currentStock,
          'reorderLevel': product.reorderLevel,
          'genericName': product.genericName,
          'brandName': product.brandName,
          'manufacturer': product.manufacturer,
        });
      } catch (_) {}
    }
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

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.put('/products/${product.id}', data: {
          'name': product.productName,
          'barcode': product.barcode,
          'category': product.category,
          'unitPrice': product.sellingPrice,
          'costPrice': product.costPrice,
          'stock': product.currentStock,
          'reorderLevel': product.reorderLevel,
          'genericName': product.genericName,
          'brandName': product.brandName,
          'manufacturer': product.manufacturer,
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final list = await getProducts();
    list.removeWhere((p) => p.id == productId);
    await _saveToStorage(list);

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.delete('/products/$productId');
      } catch (_) {}
    }
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
  final apiClient = ref.watch(apiClientProvider);
  return ProductRepositoryImpl(apiClient);
});
