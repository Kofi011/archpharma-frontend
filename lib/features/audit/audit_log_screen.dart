import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../sales/invoices_provider.dart';
import '../purchases/purchases_provider.dart';

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoicesProvider);
    final purchases = ref.watch(purchasesProvider);

    final hasActivity = invoices.isNotEmpty || purchases.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Financial Audit Trail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: !hasActivity
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_toggle_off_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No Audit Trail Records',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sales and purchase operations will appear in this audit log.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              )
            : ListView(
                children: [
                  for (final inv in invoices.take(10)) ...[
                    _buildAuditRow(
                      action: 'INVOICE_CREATE',
                      user: inv.cashierName.isNotEmpty ? inv.cashierName : 'Cashier',
                      details: 'Created invoice ${inv.invoiceNumber} for ${inv.customerName} (GHS ${inv.grandTotal.toStringAsFixed(2)})',
                      time: inv.invoiceDate.toIso8601String().split('T').first,
                      icon: Icons.receipt_long,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final po in purchases.take(10)) ...[
                    _buildAuditRow(
                      action: 'STOCK_IN',
                      user: 'Storekeeper',
                      details: 'Stock-In ${po.qty} units ${po.productName} (Batch ${po.batchNo})',
                      time: po.dateStr,
                      icon: Icons.inventory_2,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildAuditRow({
    required String action,
    required String user,
    required String details,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(details, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('Action: $action | User: $user', style: const TextStyle(fontSize: 11)),
        ),
        trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ),
    );
  }
}
