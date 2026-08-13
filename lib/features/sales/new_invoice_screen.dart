import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/invoice_model.dart';
import '../customers/customers_provider.dart';
import '../products/products_provider.dart';
import 'invoices_provider.dart';
import 'pdf_service.dart';
import 'widgets/invoice_preview_dialog.dart';

class NewInvoiceScreen extends ConsumerStatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  ConsumerState<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends ConsumerState<NewInvoiceScreen> {
  String _selectedCustomer = 'Walk-in Customer';
  String _attendantName = '';
  String _cashierName = '';
  String _paymentMethod = 'Cash';
  String _paymentStatus = 'FULL';
  final _amountPaidController = TextEditingController(text: '0.00');
  final String _dueDate = '2026-08-20';
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _invoiceItems = [];

  @override
  void dispose() {
    _amountPaidController.dispose();
    super.dispose();
  }

  void _addItem() {
    final availableProducts = ref.read(productsProvider);
    String? selectedProductId;
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0.00');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Medicine Line Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (availableProducts.isNotEmpty) ...[
                  const Text('Select from Stock or Type Custom:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    hint: const Text('Choose Stock Product...'),
                    value: selectedProductId,
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    items: availableProducts
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.productName} (Stock: ${p.currentStock}) - GHS ${p.sellingPrice.toStringAsFixed(2)}', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedProductId = val;
                        final prod = availableProducts.firstWhere((p) => p.id == val);
                        nameCtrl.text = prod.productName;
                        priceCtrl.text = prod.sellingPrice.toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Medicine Description', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Unit Price (GHS)', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                if (name.isNotEmpty && price > 0) {
                  setState(() {
                    _invoiceItems.add({
                      'productId': selectedProductId ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
                      'description': name,
                      'qty': qty,
                      'unitPrice': price,
                      'discount': 0.0,
                      'lineTotal': qty * price,
                    });
                    if (_paymentStatus == 'FULL') {
                      _amountPaidController.text = _grandTotal.toStringAsFixed(2);
                    }
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  double get _subtotal => _invoiceItems.fold(0.0, (sum, item) => sum + ((item['lineTotal'] as num?)?.toDouble() ?? 0.0));
  double get _discount => _invoiceItems.fold(0.0, (sum, item) => sum + ((item['discount'] as num?)?.toDouble() ?? 0.0));
  double get _grandTotal => _subtotal - _discount;
  double get _amountPaid => double.tryParse(_amountPaidController.text) ?? 0.0;
  double get _balanceDue => (_grandTotal - _amountPaid).clamp(0.0, double.infinity);

  InvoiceRecord _buildInvoiceRecord() {
    final invoiceNumber = 'INV-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
    final invoiceId = 'inv_${DateTime.now().millisecondsSinceEpoch}';

    final invoiceItems = _invoiceItems.map((item) {
      return InvoiceItemLine(
        id: 'line_${DateTime.now().microsecondsSinceEpoch}_${item['productId']}',
        productId: (item['productId'] as String?) ?? 'p_custom',
        description: (item['description'] as String?) ?? 'Medicine Item',
        qty: (item['qty'] as int?) ?? 1,
        unitPrice: (item['unitPrice'] as double?) ?? 0.0,
        discount: (item['discount'] as double?) ?? 0.0,
        lineTotal: (item['lineTotal'] as double?) ?? 0.0,
      );
    }).toList();

    final status = _balanceDue <= 0
        ? 'paid'
        : (_amountPaid > 0 ? 'partial' : 'unpaid');

    String? resolvedCustomerId;
    String resolvedCustomerName = 'Walk-in Customer';
    if (_selectedCustomer != 'Walk-in Customer') {
      try {
        final customers = ref.read(customersProvider);
        final cust = customers.firstWhere((c) => c.businessName == _selectedCustomer);
        resolvedCustomerId = cust.id;
        resolvedCustomerName = cust.businessName;
      } catch (_) {
        resolvedCustomerName = _selectedCustomer;
      }
    }

    return InvoiceRecord(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      customerId: resolvedCustomerId ?? '',
      customerName: resolvedCustomerName,
      cashierName: _cashierName.isNotEmpty ? _cashierName : 'Cashier',
      attendantName: _attendantName.isNotEmpty ? _attendantName : 'Attendant',
      invoiceDate: DateTime.now(),
      subtotal: _subtotal,
      discount: _discount,
      vat: 0.0,
      grandTotal: _grandTotal,
      amountPaid: _amountPaid,
      balance: _balanceDue,
      status: status,
      printCount: 1,
      items: invoiceItems,
      syncStatus: 'synced',
    );
  }

  Future<void> _saveAndGeneratePdf() async {
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medicine item to the invoice before generating.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final invoice = _buildInvoiceRecord();

      // 1. Save to local & synced invoices provider
      await ref.read(invoicesProvider.notifier).addInvoice(invoice);

      // 2. If customer is recorded and has balance, update customer ledger
      if (_selectedCustomer != 'Walk-in Customer' && _balanceDue > 0) {
        final customers = ref.read(customersProvider);
        final custIndex = customers.indexWhere((c) => c.businessName == _selectedCustomer);
        if (custIndex != -1) {
          final cust = customers[custIndex];
          final updatedCust = cust.copyWith(
            outstandingBalance: cust.outstandingBalance + _balanceDue,
          );
          await ref.read(customersProvider.notifier).updateCustomer(updatedCust);
        }
      }

      if (!mounted) return;

      // 3. Immediately launch PDF layout & print preview (no stalling)
      await PdfInvoiceService.printInvoice(invoice);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Invoice ${invoice.invoiceNumber} saved & PDF opened successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Return back to Sales ledger
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sales Invoice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card (Customer, Attendant, Cashier)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer & Staff Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer Business Name',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      items: ['Walk-in Customer', ...customers.map((c) => c.businessName)]
                          .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedCustomer = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _attendantName,
                            decoration: const InputDecoration(
                              labelText: 'Attendant Name',
                              hintText: 'e.g. Francis',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => _attendantName = val,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _cashierName,
                            decoration: const InputDecoration(
                              labelText: 'Cashier Name',
                              hintText: 'e.g. Daniel',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => _cashierName = val,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Items List
            if (_invoiceItems.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 36, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 8),
                        const Text(
                          'No items added yet. Tap "+ Add Product" to add medicines.',
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoiceItems.length,
                itemBuilder: (context, index) {
                  final item = _invoiceItems[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['description'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Unit Price: GHS ${(item['unitPrice'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  if (item['qty'] > 1) {
                                    setState(() {
                                      item['qty']--;
                                      item['lineTotal'] = item['qty'] * (item['unitPrice'] as double);
                                      if (_paymentStatus == 'FULL') {
                                        _amountPaidController.text = _grandTotal.toStringAsFixed(2);
                                      }
                                    });
                                  }
                                },
                              ),
                              Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  setState(() {
                                    item['qty']++;
                                    item['lineTotal'] = item['qty'] * (item['unitPrice'] as double);
                                    if (_paymentStatus == 'FULL') {
                                      _amountPaidController.text = _grandTotal.toStringAsFixed(2);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'GHS ${(item['lineTotal'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _invoiceItems.removeAt(index);
                                if (_paymentStatus == 'FULL') {
                                  _amountPaidController.text = _grandTotal.toStringAsFixed(2);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Total Summary Card
            Card(
              color: AppColors.surfaceSubtleLight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('GHS ${_grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment & Debt Alignment Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder(), isDense: true),
                            items: ['Cash', 'Mobile Money (MoMo)', 'Bank Transfer', 'Cheque', 'Credit Account']
                                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentStatus,
                            decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder(), isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'FULL', child: Text('FULL PAYMENT')),
                              DropdownMenuItem(value: 'PARTIAL', child: Text('PARTIAL PAYMENT')),
                              DropdownMenuItem(value: 'UNPAID', child: Text('UNPAID (CREDIT)')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _paymentStatus = val!;
                                if (_paymentStatus == 'FULL') _amountPaidController.text = _grandTotal.toStringAsFixed(2);
                                if (_paymentStatus == 'UNPAID') _amountPaidController.text = '0.00';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountPaidController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount Paid (GHS)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Balance Due:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                                Text('GHS ${_balanceDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.warning)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main Primary Action: Save & Print / Generate PDF
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _saveAndGeneratePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.print),
                label: Text(
                  _isGenerating ? 'Generating Invoice PDF...' : 'Save & Print / Share PDF',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Action: Preview Invoice
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_invoiceItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add items to preview invoice.')),
                    );
                    return;
                  }
                  showDialog(
                    context: context,
                    builder: (ctx) => InvoicePreviewDialog(
                      customerName: _selectedCustomer,
                      attendantName: _attendantName,
                      cashierName: _cashierName,
                      invoiceDateStr: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                      paymentMethod: _paymentMethod,
                      amountPaid: _amountPaid,
                      balanceDue: _balanceDue,
                      paymentDueDate: _dueDate,
                      items: _invoiceItems,
                      subtotal: _subtotal,
                      discount: _discount,
                      grandTotal: _grandTotal,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Preview Invoice Layout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
