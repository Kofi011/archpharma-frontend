import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/file_saver_util.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/invoice_model.dart';
import 'invoices_provider.dart';
import 'pdf_service.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  String _selectedStatus = 'all';

  void _showPaymentDialog(InvoiceRecord invoice) {
    final amountCtrl = TextEditingController(text: invoice.balance.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receive Payment — ${invoice.invoiceNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${invoice.customerName}'),
            Text('Outstanding Balance: GHS ${invoice.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Payment Amount (GHS)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final payment = double.tryParse(amountCtrl.text) ?? 0.0;
              if (payment > 0) {
                ref.read(invoicesProvider.notifier).recordPayment(invoice.id, payment);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment of GHS ${payment.toStringAsFixed(2)} recorded.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(invoicesProvider);
    final filteredInvoices = invoices.where((i) {
      if (_selectedStatus == 'all') return true;
      return i.status == _selectedStatus;
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
                  'Sales & Invoices Ledger',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () async {
              final headers = ['Invoice Number', 'Customer Name', 'Date', 'Subtotal', 'Discount', 'Vat', 'Grand Total', 'Amount Paid', 'Balance', 'Status'];
              final rows = filteredInvoices.map((inv) => [
                inv.invoiceNumber,
                inv.customerName,
                '${inv.invoiceDate.year}-${inv.invoiceDate.month.toString().padLeft(2, '0')}-${inv.invoiceDate.day.toString().padLeft(2, '0')}',
                inv.subtotal.toStringAsFixed(2),
                inv.discount.toStringAsFixed(2),
                inv.vat.toStringAsFixed(2),
                inv.grandTotal.toStringAsFixed(2),
                inv.amountPaid.toStringAsFixed(2),
                inv.balance.toStringAsFixed(2),
                inv.status
              ]).toList();
              final csvData = CsvExporter.convertToCsv(headers, rows);
              await FileSaverUtil.save('sales_invoices.csv', csvData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sales invoices exported as CSV successfully.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_rounded),
            tooltip: 'New Sale / Invoice',
            onPressed: () => context.push('/sales/new-invoice'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Filters Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Invoices'),
                    selected: _selectedStatus == 'all',
                    onSelected: (val) => setState(() => _selectedStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Paid'),
                    selected: _selectedStatus == 'paid',
                    onSelected: (val) => setState(() => _selectedStatus = 'paid'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Partial'),
                    selected: _selectedStatus == 'partial',
                    onSelected: (val) => setState(() => _selectedStatus = 'partial'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unpaid'),
                    selected: _selectedStatus == 'unpaid',
                    onSelected: (val) => setState(() => _selectedStatus = 'unpaid'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Invoices ListView
            Expanded(
              child: filteredInvoices.isEmpty
                  ? const Center(child: Text('No invoice records found.'))
                  : ListView.separated(
                      itemCount: filteredInvoices.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final inv = filteredInvoices[index];
                        final isPaid = inv.status == 'paid';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Text(
                                        inv.invoiceNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isPaid ? AppColors.success : AppColors.warning).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          inv.status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isPaid ? AppColors.success : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      'Customer: ${inv.customerName}\nCashier: ${inv.cashierName} | Date: ${inv.invoiceDate.year}-${inv.invoiceDate.month.toString().padLeft(2, '0')}-${inv.invoiceDate.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'GHS ${inv.grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (!isPaid)
                                        Text(
                                          'Bal: GHS ${inv.balance.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isPaid) ...[
                                      OutlinedButton.icon(
                                        onPressed: () => _showPaymentDialog(inv),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.success,
                                          side: const BorderSide(color: AppColors.success),
                                        ),
                                        icon: const Icon(Icons.payment, size: 16),
                                        label: const Text('Receive Payment'),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    ElevatedButton.icon(
                                      onPressed: () => PdfInvoiceService.printInvoice(inv),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.print, size: 16),
                                      label: const Text('Print / Share PDF'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () {
                                        _confirmDeleteInvoice(context, ref, inv);
                                      },
                                      tooltip: 'Delete Invoice',
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

  void _confirmDeleteInvoice(BuildContext context, WidgetRef ref, InvoiceRecord invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice Record'),
        content: Text('Are you sure you want to delete invoice "${invoice.invoiceNumber}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(invoicesProvider.notifier).deleteInvoice(invoice.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice "${invoice.invoiceNumber}" deleted successfully.')),
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
