import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../sync/sync_status_badge.dart';
import '../products/products_provider.dart';
import '../customers/customers_provider.dart';
import '../sales/invoices_provider.dart';
import '../../core/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userSession = ref.watch(authProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final invoices = ref.watch(invoicesProvider);
    final products = ref.watch(productsProvider);
    final customers = ref.watch(customersProvider);

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final todayInvoices = invoices.where((i) => i.invoiceDate.toIso8601String().startsWith(todayStr)).toList();
    final todaySales = todayInvoices.fold(0.0, (sum, i) => sum + i.grandTotal);
    final monthlySales = invoices.fold(0.0, (sum, i) => sum + i.grandTotal);
    final totalDebt = customers.fold(0.0, (sum, c) => sum + c.outstandingBalance);
    final inventoryValue = products.fold(0.0, (sum, p) => sum + (p.costPrice * p.currentStock));

    return Scaffold(
      appBar: AppBar(
        leading: null, // Removed hamburger menu icon
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/archpharma_logo.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.local_pharmacy, color: AppColors.primary, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ArchPharma',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                  ),
                  if (isDesktop)
                    const Text(
                      'Wholesale ERP System',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            offset: const Offset(0, 48),
            onSelected: (val) {
              if (val == 0) {
                context.push('/settings');
              } else if (val == 1) {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      radius: 16,
                      child: Text(
                        (userSession?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userSession?.name ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        Text(
                          userSession?.role.name.toUpperCase() ?? 'ROLE',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('System Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 8.0, bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      radius: 14,
                      child: Text(
                        (userSession?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userSession?.name ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimaryLight),
                        ),
                        Text(
                          userSession?.role.name.toUpperCase() ?? 'ROLE',
                          style: const TextStyle(fontSize: 8, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondaryLight),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${userSession?.name ?? "User"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: ${userSession?.role.name.toUpperCase()} | Offline Sync Engine Active (Drift SQLite)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 22,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Executive Wholesale Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // KPI Grid Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: MediaQuery.of(context).size.width < 360
                  ? 1.15
                  : (MediaQuery.of(context).size.width < 400 ? 1.25 : 1.45),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildKpiCard(
                  title: "Today's Sales",
                  value: 'GHS ${todaySales.toStringAsFixed(2)}',
                  subtitle: '${todayInvoices.length} sales today',
                  icon: Icons.monetization_on_outlined,
                  color: AppColors.primary,
                ),
                _buildKpiCard(
                  title: 'Monthly Sales',
                  value: 'GHS ${monthlySales.toStringAsFixed(2)}',
                  subtitle: '${invoices.length} total orders',
                  icon: Icons.trending_up,
                  color: AppColors.secondary,
                ),
                _buildKpiCard(
                  title: 'Outstanding Debts',
                  value: 'GHS ${totalDebt.toStringAsFixed(2)}',
                  subtitle: totalDebt > 0 ? 'Receivables due' : 'No active debt',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.warning,
                ),
                _buildKpiCard(
                  title: 'Inventory Value',
                  value: 'GHS ${inventoryValue.toStringAsFixed(2)}',
                  subtitle: '${products.length} products in catalog',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Alerts Feed
            const Text(
              'Priority Alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppColors.success),
                ),
                title: const Text('System Ready for Production'),
                subtitle: const Text('All inventory & credit levels optimal.'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of ArchPharma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
