import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../sales/pdf_service.dart';
import '../sales/invoices_provider.dart';
import '../../data/models/customer_model.dart';

class CustomerStatementDialog extends ConsumerWidget {
  final CustomerItem customer;

  const CustomerStatementDialog({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allInvoices = ref.watch(invoicesProvider);
    final customerInvoices = allInvoices.where((i) =>
        i.customerId == customer.id ||
        i.customerName.toLowerCase() == customer.businessName.toLowerCase()).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Account Statement | Contact: ${customer.contactPerson} (${customer.phone})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Credit Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobileLayout = constraints.maxWidth < 460;
                  final limitCard = _buildCreditSummaryCard(
                    'Credit Limit',
                    'GHS ${customer.creditLimit.toStringAsFixed(2)}',
                    AppColors.primary,
                  );
                  final debtCard = _buildCreditSummaryCard(
                    'Outstanding Debt',
                    'GHS ${customer.outstandingBalance.toStringAsFixed(2)}',
                    customer.hasOutstandingDebt ? AppColors.error : AppColors.success,
                    bgColor: customer.hasOutstandingDebt ? AppColors.error.withOpacity(0.08) : AppColors.success.withOpacity(0.08),
                    borderColor: customer.hasOutstandingDebt ? AppColors.error.withOpacity(0.3) : AppColors.success.withOpacity(0.3),
                  );
                  final availCard = _buildCreditSummaryCard(
                    'Available Credit',
                    'GHS ${customer.availableCredit.toStringAsFixed(2)}',
                    AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.08),
                    borderColor: AppColors.primary.withOpacity(0.2),
                  );

                  if (isMobileLayout) {
                    return Column(
                      children: [
                        limitCard,
                        const SizedBox(height: 8),
                        debtCard,
                        const SizedBox(height: 8),
                        availCard,
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(child: limitCard),
                        const SizedBox(width: 8),
                        Expanded(child: debtCard),
                        const SizedBox(width: 8),
                        Expanded(child: availCard),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              const Text('Purchase & Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              // Transaction History Table
              if (customerInvoices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      'No invoice or transaction records found for this customer.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ),
                )
              else
                Table(
                  border: TableBorder.all(color: AppColors.borderLight, borderRadius: BorderRadius.circular(4)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.8),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.2),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: AppColors.tableHeaderBg),
                      children: [
                        Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Type / Ref', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    for (final inv in customerInvoices)
                      TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(inv.invoiceDate.toIso8601String().split('T').first, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(inv.invoiceNumber, style: const TextStyle(fontSize: 11))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text('GHS ${inv.grandTotal.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(inv.status.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: inv.balance <= 0 ? AppColors.success : AppColors.warning))),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 24),

              // Responsive Action Buttons Wrapping
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close', style: TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await PdfInvoiceService.printCustomerStatement(customer);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Export Statement PDF', style: TextStyle(fontSize: 12)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/sales/new-invoice');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('New Invoice', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditSummaryCard(String title, String value, Color color, {Color? bgColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
