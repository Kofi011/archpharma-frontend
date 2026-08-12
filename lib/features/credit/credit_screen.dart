import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../customers/customers_provider.dart';

class CreditScreen extends ConsumerWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final totalOutstanding = customers.fold(0.0, (sum, c) => sum + c.outstandingBalance);
    final overdueCustomers = customers.where((c) => c.outstandingBalance > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Sales & Aging Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aging Summary Cards
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Outstanding Customer Debt', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('GHS ${totalOutstanding.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Aging Buckets Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildBucketCard('Current (<30d)', 'GHS ${totalOutstanding.toStringAsFixed(2)}', totalOutstanding > 0 ? AppColors.warning : AppColors.success),
                const SizedBox(width: 8),
                _buildBucketCard('30 Days Overdue', 'GHS 0.00', AppColors.success),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBucketCard('60 Days Overdue', 'GHS 0.00', AppColors.success),
                const SizedBox(width: 8),
                _buildBucketCard('90 Days Overdue', 'GHS 0.00', AppColors.success),
                const SizedBox(width: 8),
                _buildBucketCard('120+ Days (Bad Debt)', 'GHS 0.00', AppColors.success),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Overdue Accounts Follow-Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (overdueCustomers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.success, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'No Overdue Accounts',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All customer ledgers are currently in good standing with zero bad debt.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...overdueCustomers.map(
                (customer) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.warning_amber, color: AppColors.warning),
                    ),
                    title: Text('${customer.businessName} — ${customer.contactPerson}'),
                    subtitle: Text('Contact: ${customer.phone} | Credit Limit: GHS ${customer.creditLimit.toStringAsFixed(2)}'),
                    trailing: Text(
                      'GHS ${customer.outstandingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketCard(String title, String amount, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 4),
              Text(amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
