import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/product_model.dart';
import 'products_provider.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _sellingCtrl = TextEditingController();
  final _reorderCtrl = TextEditingController(text: '10');
  String _category = 'Antibiotics';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _genericCtrl.dispose();
    _barcodeCtrl.dispose();
    _costCtrl.dispose();
    _sellingCtrl.dispose();
    _reorderCtrl.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProd = ProductItem(
        id: const Uuid().v4(),
        barcode: _barcodeCtrl.text.isNotEmpty
            ? _barcodeCtrl.text
            : '${8900000000000 + DateTime.now().millisecondsSinceEpoch % 1000000000000}',
        productName: _nameCtrl.text,
        genericName: _genericCtrl.text,
        brandName: _nameCtrl.text.split(' ').first,
        category: _category,
        manufacturer: 'General Pharma',
        costPrice: double.tryParse(_costCtrl.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingCtrl.text) ?? 0.0,
        reorderLevel: int.tryParse(_reorderCtrl.text) ?? 10,
        status: 'active',
        currentStock: 0, // Stock starts at 0 until Stock-In event is posted to ledger
      );

      ref.read(productsProvider.notifier).addProduct(newProd);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product "${newProd.productName}" added successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Add New Medicine / Product',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const Divider(),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name', hintText: 'Enter medicine brand or trade name', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genericCtrl,
                  decoration: const InputDecoration(labelText: 'Generic / Active Ingredient', hintText: 'Enter active pharmaceutical ingredient', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isMobileLayout = constraints.maxWidth < 450;
                    final barcodeField = TextFormField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.qr_code_scanner),
                      ),
                    );
                    final categoryField = DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: ['Antibiotics', 'Dermatology', 'Analgesics', 'Cardiovascular', 'Vitamins']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    );
                    final costField = TextFormField(
                      controller: _costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cost Price (GHS)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    );
                    final sellingField = TextFormField(
                      controller: _sellingCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Selling Price (GHS)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    );

                    if (isMobileLayout) {
                      return Column(
                        children: [
                          barcodeField,
                          const SizedBox(height: 12),
                          categoryField,
                          const SizedBox(height: 12),
                          costField,
                          const SizedBox(height: 12),
                          sellingField,
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: barcodeField),
                              const SizedBox(width: 12),
                              Expanded(child: categoryField),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: costField),
                              const SizedBox(width: 12),
                              Expanded(child: sellingField),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reorderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reorder Stock Alert Level', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save Product to Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
