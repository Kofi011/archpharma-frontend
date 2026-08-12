import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/csv_exporter.dart';
import '../../core/utils/file_saver_util.dart';
import '../../core/theme/app_colors.dart';
import '../products/products_provider.dart';
import '../sales/invoices_provider.dart';
import '../customers/customers_provider.dart';
import '../sales/pdf_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoicesProvider);
    final products = ref.watch(productsProvider);
    final customers = ref.watch(customersProvider);

    double totalSales = 0.0;
    double totalCollected = 0.0;
    double totalDebt = 0.0;

    for (final inv in invoices) {
      totalSales += inv.grandTotal;
      totalCollected += inv.amountPaid;
      totalDebt += inv.balance;
    }

    if (totalDebt == 0.0 && customers.isNotEmpty) {
      totalDebt = customers.fold(0.0, (sum, c) => sum + c.outstandingBalance);
    }

    // Dynamic top-moving products from real invoices
    final Map<String, int> productSalesQty = {};
    final Map<String, double> productSalesRevenue = {};
    for (final inv in invoices) {
      for (final item in inv.items) {
        final name = item.description.replaceAll('\n', ' ');
        productSalesQty[name] = (productSalesQty[name] ?? 0) + item.qty;
        productSalesRevenue[name] = (productSalesRevenue[name] ?? 0) + item.lineTotal;
      }
    }

    final sortedTopProducts = productSalesQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Dynamic inventory & expiry risk
    final lowStockProducts = products.where((p) => p.isLowStock).toList();

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
                    color: AppColors.primary.withValues(alpha: 0.12),
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
                  'Reports & Analytics',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
            onPressed: () {
              ref.invalidate(invoicesProvider);
              ref.invalidate(productsProvider);
              ref.invalidate(customersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analytics refreshed to latest database state.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Print PDF Report',
            onPressed: () async {
              await PdfInvoiceService.printReportsSummary(totalSales, totalCollected, totalDebt, products);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () async {
              final headers = ['Metric', 'Value'];
              final rows = [
                ['Total Sales Revenue', totalSales.toStringAsFixed(2)],
                ['Cash Collected', totalCollected.toStringAsFixed(2)],
                ['Outstanding Receivables', totalDebt.toStringAsFixed(2)],
                ['Total Invoices Count', invoices.length.toString()],
                ['Total Products Count', products.length.toString()],
              ];
              final csvData = CsvExporter.convertToCsv(headers, rows);
              await FileSaverUtil.save('executive_reports_summary.csv', csvData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Executive summary exported as CSV successfully.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final cardSales = _buildReportCard('Total Sales Revenue', 'GHS ${totalSales.toStringAsFixed(2)}', AppColors.primary, Icons.payments);
                final cardCollected = _buildReportCard('Cash Collected', 'GHS ${totalCollected.toStringAsFixed(2)}', AppColors.success, Icons.account_balance_wallet);
                final cardDebt = _buildReportCard('Outstanding Receivables', 'GHS ${totalDebt.toStringAsFixed(2)}', AppColors.warning, Icons.pending_actions);
                final cardCount = _buildReportCard('Total Invoices', '${invoices.length} Orders', AppColors.secondary, Icons.receipt_long);

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cardSales,
                      const SizedBox(height: 10),
                      cardCollected,
                      const SizedBox(height: 10),
                      cardDebt,
                      const SizedBox(height: 10),
                      cardCount,
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cardSales),
                          const SizedBox(width: 10),
                          Expanded(child: cardCollected),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: cardDebt),
                          const SizedBox(width: 10),
                          Expanded(child: cardCount),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Top Fast-Moving Products
            const Text('Top Fast-Moving Medicines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: sortedTopProducts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'No sales records available. Start selling to see top-moving medicines.',
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < sortedTopProducts.take(5).length; i++) ...[
                            if (i > 0) const Divider(height: 16),
                            _buildTopProductRow(
                              '${i + 1}',
                              sortedTopProducts[i].key,
                              '${sortedTopProducts[i].value} units sold',
                              'GHS ${(productSalesRevenue[sortedTopProducts[i].key] ?? 0.0).toStringAsFixed(2)}',
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Expiry Loss Risk Summary
            const Text('Inventory Alerts & Expiry Risk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (lowStockProducts.isEmpty)
              Card(
                color: AppColors.success.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Levels Normal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All stocked products are currently above their minimum reorder thresholds.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                color: AppColors.warning.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${lowStockProducts.length} Product(s) Below Reorder Threshold',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final prod in lowStockProducts.take(3))
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '• ${prod.productName} — ${prod.currentStock} units remaining (Reorder Level: ${prod.reorderLevel})',
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductRow(String rank, String name, String unitsSold, String revenue) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            rank,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                unitsSold,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          revenue,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
