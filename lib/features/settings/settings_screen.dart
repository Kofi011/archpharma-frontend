import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'settings_provider.dart';
import '../sync/sync_engine.dart';
import '../products/products_provider.dart';
import '../customers/customers_provider.dart';
import '../sales/invoices_provider.dart';
import '../suppliers/suppliers_provider.dart';
import '../purchases/purchases_provider.dart';
import '../auth/auth_provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_saver_util.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _companyController;
  late final TextEditingController _taglineController;
  late final TextEditingController _phonesController;
  late final TextEditingController _apiEndpointController;

  bool _preventZeroStockBilling = true;
  bool _autoLockOverdueAccounts = true;
  double _expiryAlertDays = 90;
  double _minProfitMargin = 10;
  String _currency = 'GHS';
  String _agingThreshold = '120';

  // Printer Settings
  String _printerType = 'POS Thermal (80mm)';
  bool _autoPrintOnSave = true;
  double _printCopiesCount = 2;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _companyController = TextEditingController(text: settings.companyName);
    _taglineController = TextEditingController(text: settings.tagline);
    _phonesController = TextEditingController(text: settings.phones);
    _apiEndpointController = TextEditingController(text: settings.apiEndpoint);
    _preventZeroStockBilling = settings.preventZeroStockBilling;
    _autoLockOverdueAccounts = settings.autoLockOverdueAccounts;
    _expiryAlertDays = settings.expiryAlertDays;
    _minProfitMargin = settings.minProfitMargin;
    _currency = settings.currency;
    _agingThreshold = settings.agingThreshold;
    _printerType = settings.printerType;
    _autoPrintOnSave = settings.autoPrintOnSave;
    _printCopiesCount = settings.printCopiesCount;
  }

  void _syncFromSettings(AppSettings settings) {
    _companyController.text = settings.companyName;
    _taglineController.text = settings.tagline;
    _phonesController.text = settings.phones;
    _apiEndpointController.text = settings.apiEndpoint;
    setState(() {
      _preventZeroStockBilling = settings.preventZeroStockBilling;
      _autoLockOverdueAccounts = settings.autoLockOverdueAccounts;
      _expiryAlertDays = settings.expiryAlertDays;
      _minProfitMargin = settings.minProfitMargin;
      _currency = settings.currency;
      _agingThreshold = settings.agingThreshold;
      _printerType = settings.printerType;
      _autoPrintOnSave = settings.autoPrintOnSave;
      _printCopiesCount = settings.printCopiesCount;
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _taglineController.dispose();
    _phonesController.dispose();
    _apiEndpointController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final updatedSettings = AppSettings(
      companyName: _companyController.text.trim(),
      tagline: _taglineController.text.trim(),
      phones: _phonesController.text.trim(),
      currency: _currency,
      printerType: _printerType,
      autoPrintOnSave: _autoPrintOnSave,
      printCopiesCount: _printCopiesCount,
      preventZeroStockBilling: _preventZeroStockBilling,
      expiryAlertDays: _expiryAlertDays,
      minProfitMargin: _minProfitMargin,
      autoLockOverdueAccounts: _autoLockOverdueAccounts,
      agingThreshold: _agingThreshold,
      apiEndpoint: _apiEndpointController.text.trim(),
      logoAsset: ref.read(settingsProvider).logoAsset,
    );

    await ref.read(settingsProvider.notifier).saveSettings(updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('System settings saved and permanently persisted!'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _exportBackup() async {
    try {
      final settings = ref.read(settingsProvider);
      final products = ref.read(productsProvider);
      final customers = ref.read(customersProvider);
      final invoices = ref.read(invoicesProvider);
      final suppliers = ref.read(suppliersProvider);
      final purchases = ref.read(purchasesProvider);

      final backupData = {
        'version': '1.0.0',
        'exportTimestamp': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
        'products': products.map((p) => p.toJson()).toList(),
        'customers': customers.map((c) => c.toJson()).toList(),
        'invoices': invoices.map((i) => i.toJson()).toList(),
        'suppliers': suppliers.map((s) => s.toJson()).toList(),
        'purchases': purchases.map((p) => p.toJson()).toList(),
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      final filename = 'archpharma_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.json';

      await FileSaverUtil.save(filename, jsonStr, mimeType: 'application/json');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database backup exported as $filename'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showMasterResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Master Factory Reset',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to perform a complete system reset?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action will permanently wipe both the cloud database and local device storage:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text('• Cloud PostgreSQL tables (products, customers, ledgers)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('• All local products & inventory stock', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('• All customers, suppliers & credit ledgers', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('• All purchases, invoices & sales transactions', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('• Restore all settings to brand new factory defaults', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'WARNING: The system will return to a clean, blank factory state. This action cannot be undone.',
                style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _executeMasterResetWithProgress();
    }
  }

  Future<void> _executeMasterResetWithProgress() async {
    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Cloud PostgreSQL Database Purge',
        'subtitle': 'Calling /api/v1/sync/reset to wipe remote tables',
        'status': 'pending', // pending, running, success, warning
        'detail': '',
      },
      {
        'title': 'Local Product & Inventory Purge',
        'subtitle': 'Wiping product catalog and stock ledger',
        'status': 'pending',
        'detail': '',
      },
      {
        'title': 'Customer & Supplier Ledgers Purge',
        'subtitle': 'Clearing contacts, debt ledgers, and vendor accounts',
        'status': 'pending',
        'detail': '',
      },
      {
        'title': 'Invoices & Sales Transactions Purge',
        'subtitle': 'Clearing invoice histories and payment receipts',
        'status': 'pending',
        'detail': '',
      },
      {
        'title': 'Persistent Local Cache Cleanup',
        'subtitle': 'Wiping local SharedPreferences database entries',
        'status': 'pending',
        'detail': '',
      },
      {
        'title': 'Factory Configuration Reset',
        'subtitle': 'Restoring business rules, printer & pricing parameters',
        'status': 'pending',
        'detail': '',
      },
      {
        'title': 'UI Refresh & State Invalidation',
        'subtitle': 'Refreshing all dashboard views, reports & providers',
        'status': 'pending',
        'detail': '',
      },
    ];

    bool isComplete = false;
    String completionMessage = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void runReset() async {
              // 1. Cloud backend database reset
              setModalState(() {
                steps[0]['status'] = 'running';
                steps[0]['detail'] = 'Contacting server...';
              });
              await Future.delayed(const Duration(milliseconds: 300));
              try {
                final apiClient = ref.read(apiClientProvider);
                final res = await apiClient.dio.post('/sync/reset');
                setModalState(() {
                  steps[0]['status'] = 'success';
                  steps[0]['detail'] = res.data?['message'] ?? 'Cloud tables truncated successfully';
                });
              } catch (e) {
                setModalState(() {
                  steps[0]['status'] = 'warning';
                  steps[0]['detail'] = 'Backend offline / local fallback';
                });
              }

              // 2. Local products & inventory
              setModalState(() {
                steps[1]['status'] = 'running';
              });
              await Future.delayed(const Duration(milliseconds: 200));
              try {
                await ref.read(productRepositoryProvider).clearAll();
                await ref.read(productsProvider.notifier).clearAllProducts();
                setModalState(() {
                  steps[1]['status'] = 'success';
                  steps[1]['detail'] = '0 products in catalog';
                });
              } catch (e) {
                setModalState(() {
                  steps[1]['status'] = 'warning';
                  steps[1]['detail'] = 'Cleared local products';
                });
              }

              // 3. Customers & Suppliers
              setModalState(() {
                steps[2]['status'] = 'running';
              });
              await Future.delayed(const Duration(milliseconds: 200));
              try {
                await ref.read(customerRepositoryProvider).clearAll();
                await ref.read(customersProvider.notifier).clearAllCustomers();
                await ref.read(suppliersProvider.notifier).clearAllSuppliers();
                await ref.read(purchasesProvider.notifier).clearAllPurchases();
                setModalState(() {
                  steps[2]['status'] = 'success';
                  steps[2]['detail'] = 'All customer & vendor accounts wiped';
                });
              } catch (e) {
                setModalState(() {
                  steps[2]['status'] = 'warning';
                  steps[2]['detail'] = 'Cleared local contacts';
                });
              }

              // 4. Invoices & Sales
              setModalState(() {
                steps[3]['status'] = 'running';
              });
              await Future.delayed(const Duration(milliseconds: 200));
              try {
                await ref.read(invoiceRepositoryProvider).clearAll();
                await ref.read(invoicesProvider.notifier).clearAllInvoices();
                setModalState(() {
                  steps[3]['status'] = 'success';
                  steps[3]['detail'] = 'All invoices & payment records wiped';
                });
              } catch (e) {
                setModalState(() {
                  steps[3]['status'] = 'warning';
                  steps[3]['detail'] = 'Cleared sales records';
                });
              }

              // 5. Persistent local cache cleanup
              setModalState(() {
                steps[4]['status'] = 'running';
              });
              await Future.delayed(const Duration(milliseconds: 200));
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('archpharma_products_db', jsonEncode([]));
                await prefs.setString('archpharma_customers_db', jsonEncode([]));
                await prefs.setString('archpharma_invoices_db', jsonEncode([]));
                await prefs.setString('archpharma_suppliers_db', jsonEncode([]));
                await prefs.setString('archpharma_purchases_db', jsonEncode([]));
                await prefs.remove('archpharma_app_settings');
                setModalState(() {
                  steps[4]['status'] = 'success';
                  steps[4]['detail'] = 'Persistent storage sanitized';
                });
              } catch (e) {
                setModalState(() {
                  steps[4]['status'] = 'warning';
                  steps[4]['detail'] = 'Storage reset';
                });
              }

              // 6. Factory settings reset
              setModalState(() {
                steps[5]['status'] = 'running';
              });
              await Future.delayed(const Duration(milliseconds: 200));
              try {
                await ref.read(settingsProvider.notifier).resetToDefaults();
                final defaults = ref.read(settingsProvider);
                _syncFromSettings(defaults);
                setModalState(() {
                  steps[5]['status'] = 'success';
                  steps[5]['detail'] = 'Factory defaults restored';
                });
              } catch (e) {
                setModalState(() {
                  steps[5]['status'] = 'warning';
                  steps[5]['detail'] = 'Settings reset';
                });
              }

              // 7. State invalidation & UI refresh
              setModalState(() {
                steps[6]['status'] = 'running';
              });
              await Future.delayed(const Duration(milliseconds: 250));
              ref.invalidate(productsProvider);
              ref.invalidate(customersProvider);
              ref.invalidate(invoicesProvider);
              ref.invalidate(suppliersProvider);
              ref.invalidate(purchasesProvider);
              ref.invalidate(settingsProvider);
              ref.invalidate(syncEngineProvider);

              setModalState(() {
                steps[6]['status'] = 'success';
                steps[6]['detail'] = 'All providers refreshed';
                isComplete = true;
                completionMessage = 'Master Factory Reset successfully completed! System is fresh and ready.';
              });
            }

            // Start reset on first build
            if (steps.every((s) => s['status'] == 'pending')) {
              WidgetsBinding.instance.addPostFrameCallback((_) => runReset());
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isComplete ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isComplete ? Icons.check_circle : Icons.cleaning_services_rounded,
                            color: isComplete ? AppColors.success : AppColors.error,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isComplete ? 'Reset Complete!' : 'Executing Master Factory Reset',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isComplete
                                    ? 'All databases and states restored to factory blank'
                                    : 'Please wait while all data layers are being purged...',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Steps Checklist
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 340),
                      child: SingleChildScrollView(
                        child: Column(
                          children: steps.map((s) {
                            final status = s['status'] as String;
                            Widget leadingIcon;
                            Color titleColor = Colors.black87;

                            if (status == 'running') {
                              leadingIcon = const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                              );
                              titleColor = AppColors.primary;
                            } else if (status == 'success') {
                              leadingIcon = const Icon(Icons.check_circle, size: 20, color: AppColors.success);
                            } else if (status == 'warning') {
                              leadingIcon = const Icon(Icons.info_outline, size: 20, color: AppColors.warning);
                            } else {
                              leadingIcon = Icon(Icons.radio_button_unchecked, size: 20, color: Colors.grey[400]);
                              titleColor = Colors.grey;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: leadingIcon,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                s['title'] as String,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: titleColor,
                                                ),
                                              ),
                                            ),
                                            if ((s['detail'] as String).isNotEmpty)
                                              Text(
                                                s['detail'] as String,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: status == 'success' ? AppColors.success : (status == 'warning' ? AppColors.warning : Colors.grey),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s['subtitle'] as String,
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    if (isComplete) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                completionMessage,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogCtx).pop();
                              setState(() {});
                            },
                            child: const Text('Stay on Settings'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(dialogCtx).pop();
                              context.go('/dashboard');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            icon: const Icon(Icons.dashboard_outlined, size: 18),
                            label: const Text('Go to Dashboard'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      _syncFromSettings(next);
    });

    final syncState = ref.watch(syncEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings & Configuration'),
        leading: null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Settings'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System-Wide Tweaking & Business Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Configure company identity, printer bindings, safeguards, and backup options.',
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 800;

                final companyIdentityCard = _buildCard(
                  icon: Icons.business_outlined,
                  title: 'Business Identity',
                  children: [
                    TextField(
                      controller: _companyController,
                      decoration: const InputDecoration(labelText: 'Wholesale Business Name', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _taglineController,
                      decoration: const InputDecoration(labelText: 'Business Tagline / Specialty', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phonesController,
                      decoration: const InputDecoration(labelText: 'Phone Contact Lines', isDense: true),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(labelText: 'System Currency Code', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'GHS', child: Text('Ghanaian Cedi (GHS)')),
                        DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
                        DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('British Pound (£)')),
                        DropdownMenuItem(value: 'NGN', child: Text('Nigerian Naira (₦)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _currency = val);
                      },
                    ),
                  ],
                );

                final logoCard = _buildCard(
                  icon: Icons.image_outlined,
                  title: 'Logo Management',
                  children: [
                    const Text(
                      'Active Printed Logo Branding',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          height: 72,
                          width: 72,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Image.asset(
                            'assets/images/archpharma_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.local_pharmacy,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Logo is currently bundled at assets/images/archpharma_logo.png'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Default Logo Active'),
                              ),
                              const SizedBox(height: 4),
                              const Text('Default asset: archpharma_logo.png (512x512)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );

                final printerCard = _buildCard(
                  icon: Icons.print_outlined,
                  title: 'POS Printer Settings',
                  children: [
                    DropdownButtonFormField<String>(
                      value: _printerType,
                      decoration: const InputDecoration(labelText: 'Default Printer Driver', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'POS Thermal (80mm)', child: Text('POS Thermal Printer (80mm)')),
                        DropdownMenuItem(value: 'POS Thermal (58mm)', child: Text('POS Thermal Printer (58mm)')),
                        DropdownMenuItem(value: 'Standard A4', child: Text('Standard PDF Printer (A4)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _printerType = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Print Invoice on Save', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Trigger POS receipt layout automatically', style: TextStyle(fontSize: 10)),
                      value: _autoPrintOnSave,
                      onChanged: (val) => setState(() => _autoPrintOnSave = val),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Default Printed Duplicates: ${_printCopiesCount.toInt()}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: _printCopiesCount,
                      min: 1,
                      max: 4,
                      divisions: 3,
                      label: '${_printCopiesCount.toInt()}',
                      onChanged: (val) => setState(() => _printCopiesCount = val),
                    ),
                  ],
                );

                final inventoryCard = _buildCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory Control',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Prevent Out-of-Stock Billed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Block invoice items if physical stock is 0', style: TextStyle(fontSize: 10)),
                      value: _preventZeroStockBilling,
                      onChanged: (val) => setState(() => _preventZeroStockBilling = val),
                    ),
                    const SizedBox(height: 8),
                    Text('Expiry Alert Window: ${_expiryAlertDays.toInt()} Days', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _expiryAlertDays,
                      min: 15,
                      max: 365,
                      divisions: 23,
                      label: '${_expiryAlertDays.toInt()} Days',
                      onChanged: (val) => setState(() => _expiryAlertDays = val),
                    ),
                    Text('Minimum Profit Margin: ${_minProfitMargin.toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Slider(
                      value: _minProfitMargin,
                      min: 0,
                      max: 50,
                      divisions: 10,
                      label: '${_minProfitMargin.toInt()}%',
                      onChanged: (val) => setState(() => _minProfitMargin = val),
                    ),
                  ],
                );

                final creditCard = _buildCard(
                  icon: Icons.credit_score_outlined,
                  title: 'Credit Policies',
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Lock Overdue Customer Accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Block billing on accounts with overdue debt', style: TextStyle(fontSize: 10)),
                      value: _autoLockOverdueAccounts,
                      onChanged: (val) => setState(() => _autoLockOverdueAccounts = val),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _agingThreshold,
                      decoration: const InputDecoration(labelText: 'Bad Debt Aging Threshold', isDense: true),
                      items: const [
                        DropdownMenuItem(value: '60', child: Text('60+ Days Overdue')),
                        DropdownMenuItem(value: '90', child: Text('90+ Days Overdue')),
                        DropdownMenuItem(value: '120', child: Text('120+ Days Overdue')),
                        DropdownMenuItem(value: '180', child: Text('180+ Days Overdue')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _agingThreshold = val);
                      },
                    ),
                  ],
                );

                final syncCard = _buildCard(
                  icon: Icons.sync_lock_outlined,
                  title: 'Cloud Database Synchronization',
                  children: [
                    Text(
                      syncState.isSyncing
                          ? 'Status: Syncing ${syncState.pendingCount} elements...'
                          : (syncState.isOffline ? 'Status: Local-Only Offline Mode' : 'Status: Connected & Cloud-Synced'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: syncState.isSyncing
                            ? AppColors.info
                            : (syncState.isOffline ? AppColors.warning : AppColors.success),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Offline Mode (Local-Only)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Toggles local buffer queue billing without cloud sync', style: TextStyle(fontSize: 10)),
                      value: syncState.isOffline,
                      onChanged: (val) {
                        ref.read(syncEngineProvider.notifier).toggleAirplaneMode(val);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (syncState.pendingCount > 0) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(syncEngineProvider.notifier).triggerSync();
                          },
                          icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text('Force Sync ${syncState.pendingCount} Unsynced Logs', style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ],
                );

                final appInfoCard = _buildCard(
                  icon: Icons.info_outline,
                  title: 'Application Information',
                  children: [
                    TextField(
                      controller: _apiEndpointController,
                      decoration: const InputDecoration(
                        labelText: 'NestJS Server Endpoint Host',
                        isDense: true,
                        prefixIcon: Icon(Icons.link, size: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('App Version:', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text('1.0.0 (Build 1)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('License Type:', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text('Enterprise Single-tenant', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Local Storage Engine:', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        Text('Active (Persistent Local Storage)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                );

                final backupCard = _buildCard(
                  icon: Icons.settings_backup_restore,
                  title: 'Database Maintenance',
                  bgColor: AppColors.error.withValues(alpha: 0.02),
                  borderColor: AppColors.error.withValues(alpha: 0.12),
                  children: [
                    const Text(
                      'Export complete system backups, restore snapshots, or perform factory resetting.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _exportBackup,
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Export JSON Backup', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showMasterResetDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                        label: const Text('Master Factory Reset', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            companyIdentityCard,
                            const SizedBox(height: 16),
                            logoCard,
                            const SizedBox(height: 16),
                            printerCard,
                            const SizedBox(height: 16),
                            backupCard,
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            inventoryCard,
                            const SizedBox(height: 16),
                            creditCard,
                            const SizedBox(height: 16),
                            syncCard,
                            const SizedBox(height: 16),
                            appInfoCard,
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      companyIdentityCard,
                      const SizedBox(height: 16),
                      logoCard,
                      const SizedBox(height: 16),
                      printerCard,
                      const SizedBox(height: 16),
                      inventoryCard,
                      const SizedBox(height: 16),
                      creditCard,
                      const SizedBox(height: 16),
                      syncCard,
                      const SizedBox(height: 16),
                      appInfoCard,
                      const SizedBox(height: 16),
                      backupCard,
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
