import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/product_model.dart';
import '../products/products_provider.dart';

class StockInDialog extends ConsumerStatefulWidget {
  final ProductItem product;

  const StockInDialog({super.key, required this.product});

  @override
  ConsumerState<StockInDialog> createState() => _StockInDialogState();
}

class _StockInDialogState extends ConsumerState<StockInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _batchNumCtrl = TextEditingController(text: 'BT-9045');
  final _qtyCtrl = TextEditingController(text: '50');
  final _costCtrl = TextEditingController();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _costCtrl.text = widget.product.costPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _batchNumCtrl.dispose();
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _submitStockIn() {
    if (_formKey.currentState!.validate()) {
      final qty = int.parse(_qtyCtrl.text);
      final newStock = widget.product.currentStock + qty;

      ref.read(productsProvider.notifier).updateStock(widget.product.id, newStock);

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock-In Recorded: +$qty units for "${widget.product.productName}" (Batch ${_batchNumCtrl.text}). Ledger Updated.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 450),
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
                    const Text('Stock-In / Receive Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const Divider(),
                Text(
                  'Product: ${widget.product.productName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                Text(
                  'Current Calculated Stock: ${widget.product.currentStock} units',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _batchNumCtrl,
                  decoration: const InputDecoration(labelText: 'Batch Number', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Batch number required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity (Units)', border: OutlineInputBorder()),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter valid quantity' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Purchase Cost (GHS)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date (Mandatory for FIFO)'),
                  subtitle: Text(
                    '${_expiryDate.year}-${_expiryDate.month.toString().padLeft(2, '0')}-${_expiryDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _submitStockIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.input),
                    label: const Text('Commit Stock-In to Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
