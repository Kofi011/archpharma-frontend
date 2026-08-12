import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/invoice_model.dart';
import '../pdf_service.dart';

class InvoicePreviewDialog extends StatelessWidget {
  final String customerName;
  final String attendantName;
  final String cashierName;
  final String invoiceNumber;
  final String invoiceDateStr;
  final int printCount;
  final String invoiceStatus;
  final String paymentMethod;
  final double amountPaid;
  final double balanceDue;
  final String paymentDueDate;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double grandTotal;

  const InvoicePreviewDialog({
    super.key,
    required this.customerName,
    required this.attendantName,
    required this.cashierName,
    this.invoiceNumber = '',
    required this.invoiceDateStr,
    this.printCount = 2,
    this.invoiceStatus = 'Completed',
    this.paymentMethod = 'Cash',
    this.amountPaid = 0.0,
    this.balanceDue = 0.0,
    this.paymentDueDate = '',
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 500;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Action Toolbar
                  _buildToolbar(context, isMobile),
                  const Divider(height: 16),

                  // Company Header
                  _buildCompanyHeader(isMobile),
                  const SizedBox(height: 12),

                  // Title
                  const Text(
                    'INVOICE.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metadata section
                  _buildMetaSection(isMobile),
                  const SizedBox(height: 16),

                  // Items Table
                  _buildItemsTable(isMobile),
                  const SizedBox(height: 12),

                  // Summary Total row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: $invoiceStatus',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Total to Pay: GHS ${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payment Breakdown
                  _buildPaymentBreakdown(isMobile),
                  const SizedBox(height: 16),

                  // Footer Notice Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.invoiceFooterBar,
                    child: const Text(
                      'This is an electronic generated invoice',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InvoiceRecord _toInvoiceRecord() {
    final invNum = invoiceNumber.isNotEmpty
        ? invoiceNumber
        : 'INV-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
    final invItems = items.map((item) => InvoiceItemLine(
          id: 'line_${DateTime.now().microsecondsSinceEpoch}',
          productId: (item['productId'] as String?) ?? 'p_custom',
          description: (item['description'] as String?) ?? 'Medicine',
          qty: (item['qty'] as int?) ?? 1,
          unitPrice: (item['unitPrice'] as double?) ?? 0.0,
          discount: (item['discount'] as double?) ?? 0.0,
          lineTotal: (item['lineTotal'] as double?) ?? 0.0,
        )).toList();

    return InvoiceRecord(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: invNum,
      customerId: customerName,
      customerName: customerName,
      cashierName: cashierName.isNotEmpty ? cashierName : 'Cashier',
      attendantName: attendantName.isNotEmpty ? attendantName : 'Attendant',
      invoiceDate: DateTime.now(),
      subtotal: subtotal,
      discount: discount,
      vat: 0.0,
      grandTotal: grandTotal,
      amountPaid: amountPaid,
      balance: balanceDue,
      status: balanceDue <= 0 ? 'paid' : (amountPaid > 0 ? 'partial' : 'unpaid'),
      printCount: printCount,
      items: invItems,
      syncStatus: 'synced',
    );
  }

  Widget _buildToolbar(BuildContext context, bool isMobile) {
    final actionsList = [
      OutlinedButton.icon(
        onPressed: () async {
          try {
            final inv = _toInvoiceRecord();
            await PdfInvoiceService.printInvoice(inv);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Print Error: $e')),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        icon: const Icon(Icons.print_outlined, size: 16),
        label: const Text('Print', style: TextStyle(fontSize: 11)),
      ),
      const SizedBox(width: 6),
      ElevatedButton.icon(
        onPressed: () async {
          try {
            final inv = _toInvoiceRecord();
            await PdfInvoiceService.printInvoice(inv);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export Error: $e')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        icon: const Icon(Icons.file_download_outlined, size: 16),
        label: const Text('Export PDF', style: TextStyle(fontSize: 11)),
      ),
      IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Invoice Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actionsList,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Invoice Preview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          Row(children: actionsList),
        ],
      );
    }
  }

  Widget _buildCompanyHeader(bool isMobile) {
    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        'assets/images/archpharma_logo.png',
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.local_pharmacy, size: 18, color: AppColors.primary),
        ),
      ),
    );

    final titleText = const Text(
      'ARCH PHARMACY LTD.',
      style: TextStyle(
        fontFamily: 'Serif',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: Colors.black87,
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          logoWidget,
          const SizedBox(height: 4),
          titleText,
          const SizedBox(height: 2),
          const Text(
            '(WHOLESALERS OF PRESCRIPTION DRUGS)',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const Text(
            '0596549541 / 0534340375',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logoWidget,
              const SizedBox(width: 8),
              titleText,
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '(WHOLESALERS OF PRESCRIPTION DRUGS)',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const Text(
            '0596549541 / 0534340375',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      );
    }
  }

  Widget _buildMetaSection(bool isMobile) {
    final customerCol = [
      _buildMetaText('CUSTOMER', customerName),
      _buildMetaText('ATTENDANT', attendantName),
      _buildMetaText('CASHIER', cashierName),
    ];
    final invoiceCol = [
      _buildMetaText('DATE', invoiceDateStr, labelWidth: 80),
      _buildMetaText('INVOICE #', invoiceNumber.isNotEmpty ? invoiceNumber : 'INV-${DateTime.now().millisecondsSinceEpoch % 100000}', labelWidth: 80),
      _buildMetaText('NO OF PRINT', '$printCount Duplicate', labelWidth: 80),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...customerCol,
          const SizedBox(height: 4),
          const Divider(height: 8),
          const SizedBox(height: 4),
          ...invoiceCol,
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: customerCol),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: invoiceCol),
        ],
      );
    }
  }

  Widget _buildItemsTable(bool isMobile) {
    if (isMobile) {
      // 3-Column layout for Mobile
      return Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
        columnWidths: const {
          0: FixedColumnWidth(36), // Qty
          1: FlexColumnWidth(3),   // Description + details subtext
          2: FixedColumnWidth(76), // Line total
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppColors.tableHeaderBg),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text('Description & Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          ...items.map((item) {
            final unitPrice = (item['unitPrice'] as double);
            final discount = item['discount'] as double? ?? 0.0;
            final hasDiscount = discount > 0;
            final subText = 'GHS ${unitPrice.toStringAsFixed(2)} each' + (hasDiscount ? ' | Disc: GHS ${discount.toStringAsFixed(2)}' : '');

            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Text('${item['qty']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item['description']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 1),
                      Text(subText, style: const TextStyle(fontSize: 9, color: Colors.black54)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: Text('${(item['lineTotal'] as double).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }),
        ],
      );
    } else {
      // Standard 5-Column layout for Desktop
      return Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1.0),
        columnWidths: const {
          0: FixedColumnWidth(48),
          1: FlexColumnWidth(3),
          2: FixedColumnWidth(90),
          3: FixedColumnWidth(80),
          4: FixedColumnWidth(90),
        },
        children: [
          const TableRow(
            decoration: BoxDecoration(color: AppColors.tableHeaderBg),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text('Unit Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text('Discount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
              ),
            ],
          ),
          ...items.map((item) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text('${item['qty']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text('${item['description']}', style: const TextStyle(fontSize: 12, height: 1.3)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text('${(item['unitPrice'] as double).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(item['discount'] != null ? '${(item['discount'] as double).toStringAsFixed(2)}' : '-', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text('${(item['lineTotal'] as double).toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }),
        ],
      );
    }
  }

  Widget _buildPaymentBreakdown(bool isMobile) {
    if (isMobile) {
      // 2x2 grid for Mobile
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtleLight,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildPaymentMetaItem('Payment Method', paymentMethod, AppColors.textPrimaryLight)),
                Expanded(child: _buildPaymentMetaItem('Payment Status', invoiceStatus, AppColors.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildPaymentMetaItem('Amount Paid', 'GHS ${amountPaid.toStringAsFixed(2)}', AppColors.success)),
                Expanded(child: _buildPaymentMetaItem('Balance Due', 'GHS ${balanceDue.toStringAsFixed(2)}', AppColors.error)),
              ],
            ),
          ],
        ),
      );
    } else {
      // Row layout for Wide
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtleLight,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPaymentMetaItem('Payment Method', paymentMethod, AppColors.textPrimaryLight),
            _buildPaymentMetaItem('Payment Status', invoiceStatus, AppColors.primary),
            _buildPaymentMetaItem('Amount Paid', 'GHS ${amountPaid.toStringAsFixed(2)}', AppColors.success),
            _buildPaymentMetaItem('Balance Due', 'GHS ${balanceDue.toStringAsFixed(2)}', AppColors.error),
          ],
        ),
      );
    }
  }

  Widget _buildMetaText(String label, String value, {double labelWidth = 90}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 11),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMetaItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}
