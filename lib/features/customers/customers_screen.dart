import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/customer_model.dart';

import '../../core/theme/app_colors.dart';
import 'add_customer_dialog.dart';
import 'customer_statement_dialog.dart';
import 'customers_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final filtered = customers.where((c) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return c.businessName.toLowerCase().contains(q) ||
          c.contactPerson.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
                  'Customer Accounts & Credit Limits',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        leading: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'New Customer Profile',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const AddCustomerDialog(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Customer Accounts',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/suppliers'),
                        child: Container(
                          color: Colors.transparent,
                          child: const Center(
                            child: Text(
                              'Wholesale Suppliers',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
                            ),
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
                      hintText: 'Search pharmacy by business name, contact person, or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const AddCustomerDialog(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('New Profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No customer accounts found.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        final hasDebt = c.outstandingBalance > 0;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(c.businessName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Contact: ${c.contactPerson} (${c.phone})\nEmail: ${c.email} | Address: ${c.address}',
                                      style: const TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'GHS ${c.outstandingBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: hasDebt ? AppColors.error : AppColors.success,
                                        ),
                                      ),
                                      Text(
                                        hasDebt ? 'Outstanding Balance' : 'Clear (No Debt)',
                                        style: TextStyle(fontSize: 11, color: hasDebt ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Credit Limit Bar Meter
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: c.creditUtilization.clamp(0.0, 1.0),
                                          minHeight: 6,
                                          backgroundColor: AppColors.borderLight,
                                          color: c.isCreditOverLimit
                                              ? AppColors.error
                                              : (c.creditUtilization > 0.8 ? AppColors.warning : AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Credit Limit: GHS ${c.creditLimit.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Available Credit: GHS ${c.availableCredit.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => CustomerStatementDialog(customer: c),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          ),
                                          icon: const Icon(Icons.receipt_long, size: 16),
                                          label: const Text('View Statement', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () {
                                            _confirmDeleteCustomer(context, ref, c);
                                          },
                                          tooltip: 'Delete Customer Account',
                                        ),
                                      ],
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

  void _confirmDeleteCustomer(BuildContext context, WidgetRef ref, CustomerItem customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer Account'),
        content: Text('Are you sure you want to delete customer account "${customer.businessName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(customersProvider.notifier).deleteCustomer(customer.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Customer account "${customer.businessName}" deleted successfully.')),
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
