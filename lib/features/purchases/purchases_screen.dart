import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/purchase_model.dart';
import '../products/products_provider.dart';
import 'purchases_provider.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _viewInvoiceDialog(PurchaseItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Purchase Invoice Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildInvoiceField('Order Code:', item.orderNo),
              _buildInvoiceField('Supplier Name:', item.supplierName),
              _buildInvoiceField('Date Logged:', item.dateStr),
              _buildInvoiceField('Product Restocked:', item.productName),
              _buildInvoiceField('Batch Assigned:', item.batchNo),
              _buildInvoiceField('Quantity Purchased:', '${item.qty} units'),
              _buildInvoiceField('Total Value Cost:', 'GHS ${item.cost.toStringAsFixed(2)}', isBoldValue: true, valueColor: AppColors.primary),
              _buildInvoiceField('Delivery Status:', item.status, isBoldValue: true, valueColor: item.status.toLowerCase().contains('completed') ? AppColors.success : AppColors.warning),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sending print command to A4 office printer...')),
                    );
                  },
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print Purchase Order Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceField(String label, String value, {bool isBoldValue = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _newPurchaseDialog() {
    final formKey = GlobalKey<FormState>();
    final supplierCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final batchCtrl = TextEditingController(text: 'BT-${DateTime.now().millisecondsSinceEpoch % 10000}');
    
    final productsList = ref.read(productsProvider);
    final productCtrl = TextEditingController(text: productsList.isNotEmpty ? productsList.first.productName : '');
    String? selectedProduct = productsList.isNotEmpty ? productsList.first.productName : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Stock-In Purchase Order',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (productsList.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: selectedProduct,
                        decoration: const InputDecoration(
                          labelText: 'Select Restock Product',
                          border: OutlineInputBorder(),
                        ),
                        items: productsList.map((p) => DropdownMenuItem(value: p.productName, child: Text(p.productName))).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedProduct = val;
                            productCtrl.text = val ?? '';
                          });
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Product required' : null,
                      )
                    else
                      TextFormField(
                        controller: productCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          hintText: 'Enter medicine name to restock',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Product name required' : null,
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Supplier required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total Cost (GHS)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Cost required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity (Items)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Quantity required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: batchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Batch Code / Batch #',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Batch code required' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final currentPurchases = ref.read(purchasesProvider);
                            final prodName = (selectedProduct != null && selectedProduct!.isNotEmpty)
                                ? selectedProduct!
                                : productCtrl.text.trim();
                            final newPurchase = PurchaseItem(
                              orderNo: 'PO-2026-${100 + currentPurchases.length + 1}',
                              supplierName: supplierCtrl.text.trim(),
                              dateStr: DateTime.now().toString().split(' ').first,
                              productName: prodName,
                              cost: double.tryParse(costCtrl.text) ?? 0.0,
                              qty: int.tryParse(qtyCtrl.text) ?? 0,
                              status: 'Completed',
                              batchNo: batchCtrl.text.trim(),
                            );
                            ref.read(purchasesProvider.notifier).addPurchase(newPurchase);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Purchase order for "$prodName" saved successfully.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Log Purchase Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeletePurchase(PurchaseItem purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Record'),
        content: Text('Are you sure you want to delete purchase record "${purchase.orderNo}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(purchasesProvider.notifier).deletePurchase(purchase.orderNo);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Purchase record "${purchase.orderNo}" deleted successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final purchases = ref.watch(purchasesProvider);
    final filtered = purchases.where((p) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return p.supplierName.toLowerCase().contains(q) ||
          p.orderNo.toLowerCase().contains(q) ||
          p.productName.toLowerCase().contains(q) ||
          p.status.toLowerCase().contains(q);
    }).toList();

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
                  'Purchases & restocks',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        leading: null, // Removed hamburger menu icon
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'Log Purchase',
            onPressed: _newPurchaseDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                      child: GestureDetector(
                        onTap: () => context.go('/inventory'),
                        child: Container(
                          color: Colors.transparent,
                          child: const Center(
                            child: Text(
                              'Medicines Catalog',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                            'Purchases Log',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search purchase orders by code, supplier, or product...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _newPurchaseDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Log PO'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No purchase records found.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final isCompleted = p.status.toLowerCase() == 'completed';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobileCard = constraints.maxWidth < 450;
                                final detailsColumn = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          p.orderNo,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isCompleted ? AppColors.success : AppColors.warning).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            p.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: isCompleted ? AppColors.success : AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('Product: ${p.productName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Supplier: ${p.supplierName}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight)),
                                    Text('Date Logged: ${p.dateStr} | Batch: ${p.batchNo}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                    Text('Stock Quantity: ${p.qty} units', style: const TextStyle(fontSize: 12)),
                                  ],
                                );

                                if (isMobileCard) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      detailsColumn,
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => _viewInvoiceDialog(p),
                                            child: const Text('View Invoice'),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            onPressed: () => _confirmDeletePurchase(p),
                                            tooltip: 'Delete PO',
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                } else {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: detailsColumn),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'GHS ${p.cost.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              OutlinedButton(
                                                onPressed: () => _viewInvoiceDialog(p),
                                                style: OutlinedButton.styleFrom(),
                                                child: const Text('View Invoice', style: TextStyle(fontSize: 11)),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                onPressed: () => _confirmDeletePurchase(p),
                                                tooltip: 'Delete PO',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              },
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
}
