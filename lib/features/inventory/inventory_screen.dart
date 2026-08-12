import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/product_model.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/file_saver_util.dart';
import '../../core/theme/app_colors.dart';
import '../products/add_product_dialog.dart';
import '../products/products_provider.dart';
import 'stock_in_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final filteredProducts = products.where((p) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return p.productName.toLowerCase().contains(q) ||
          p.genericName.toLowerCase().contains(q) ||
          p.barcode.contains(q);
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/archpharma_logo.png',
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.local_pharmacy, color: AppColors.primary, size: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ArchPharma',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                Text(
                  'Inventory & Stock Ledger',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        leading: null, // Removed hamburger menu icon
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () async {
              final headers = ['ID', 'Barcode', 'Product Name', 'Generic Name', 'Category', 'Stock Level', 'Cost Price', 'Selling Price'];
              final rows = filteredProducts.map((p) => [
                p.id,
                p.barcode,
                p.productName,
                p.genericName ?? '',
                p.category ?? '',
                p.currentStock,
                p.costPrice.toStringAsFixed(2),
                p.sellingPrice.toStringAsFixed(2)
              ]).toList();
              final csvData = CsvExporter.convertToCsv(headers, rows);
              await FileSaverUtil.save('inventory_ledger.csv', csvData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inventory ledger exported as CSV successfully.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add New Product',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const AddProductDialog(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDesktop) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Medicines Catalog',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/purchases'),
                        child: Container(
                          color: Colors.transparent,
                          child: const Center(
                            child: Text(
                              'Purchases Log',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Search & Filter Header
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search medicine by name, generic, or scan barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _filter = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _filter = val),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const AddProductDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ledger Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock counts are calculated in real-time from the append-only stock_movements ledger (FIFO expiry active).',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product Catalog & Stock List
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: AppColors.textSecondaryLight),
                          const SizedBox(height: 8),
                          Text('No medicines found matching "$_filter"'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredProducts.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isLowStock = product.isLowStock;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.productName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      if (isLowStock)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'LOW STOCK',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Generic: ${product.genericName} | Barcode: ${product.barcode}\nCategory: ${product.category} | Reorder Level: ${product.reorderLevel} units',
                                      style: const TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock: ${product.currentStock}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isLowStock ? AppColors.error : AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        'Cost: GHS ${product.costPrice.toStringAsFixed(2)} | Sell: GHS ${product.sellingPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Margin: GHS ${product.margin.toStringAsFixed(2)} / unit',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => StockInDialog(product: product),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          icon: const Icon(Icons.move_to_inbox, size: 16),
                                          label: const Text('Stock In Batch', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () {
                                            _confirmDeleteProduct(context, ref, product);
                                          },
                                          tooltip: 'Delete Product',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, ProductItem product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product from Catalog'),
        content: Text('Are you sure you want to delete product "${product.productName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Product "${product.productName}" deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
