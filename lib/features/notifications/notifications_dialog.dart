import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../products/products_provider.dart';
import '../customers/customers_provider.dart';

class NotificationsDialog extends ConsumerWidget {
  const NotificationsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final customers = ref.watch(customersProvider);

    final lowStockItems = products.where((p) => p.isLowStock).toList();
    final highDebtCustomers = customers.where((c) => c.outstandingBalance > 0).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('System Alerts & Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            const Divider(),

            if (lowStockItems.isEmpty && highDebtCustomers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.done_all, color: AppColors.success, size: 32),
                      SizedBox(height: 8),
                      Text('No Active Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Stock levels and customer accounts are all in order.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              )
            else ...[
              for (final prod in lowStockItems.take(2))
                ListTile(
                  leading: const Icon(Icons.error_outline, color: AppColors.error),
                  title: Text('Low Stock: ${prod.productName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Stock fallen to ${prod.currentStock} units (Reorder: ${prod.reorderLevel}).'),
                ),
              for (final cust in highDebtCustomers.take(2))
                ListTile(
                  leading: const Icon(Icons.credit_card_outlined, color: AppColors.warning),
                  title: Text('Outstanding Balance: ${cust.businessName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Outstanding debt: GHS ${cust.outstandingBalance.toStringAsFixed(2)}'),
                ),
            ],
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
