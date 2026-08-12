import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductsNotifier extends StateNotifier<List<ProductItem>> {
  final ProductRepository _repository;

  ProductsNotifier(this._repository) : super([]) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _repository.getProducts();
    state = products;
  }

  Future<void> addProduct(ProductItem product) async {
    await _repository.addProduct(product);
    await _loadProducts();
  }

  Future<void> updateStock(String productId, int newStock) async {
    final itemIndex = state.indexWhere((p) => p.id == productId);
    if (itemIndex != -1) {
      final old = state[itemIndex];
      final updated = ProductItem(
        id: old.id,
        barcode: old.barcode,
        productName: old.productName,
        genericName: old.genericName,
        brandName: old.brandName,
        category: old.category,
        manufacturer: old.manufacturer,
        costPrice: old.costPrice,
        sellingPrice: old.sellingPrice,
        reorderLevel: old.reorderLevel,
        status: old.status,
        currentStock: newStock,
      );
      await _repository.updateProduct(updated);
      await _loadProducts();
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _repository.deleteProduct(productId);
    await _loadProducts();
  }

  Future<void> clearAllProducts() async {
    await _repository.clearAll();
    state = [];
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    await _loadProducts();
  }

  ProductItem? findByBarcode(String barcode) {
    try {
      return state.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductItem>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductsNotifier(repository);
});
