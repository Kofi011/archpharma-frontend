import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/product_model.dart';

class PdfInvoiceService {
  
  /// Helper to load logo with safe fallback that never hangs
  static Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData byteData = await rootBundle
          .load('assets/images/archpharma_logo.png')
          .timeout(const Duration(milliseconds: 1500));
      final Uint8List bytes = byteData.buffer.asUint8List();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Helper to draw company header with optional logo
  static pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          pw.Container(
            width: 48,
            height: 48,
            child: pw.Image(logo),
          ),
          pw.SizedBox(width: 12),
        ] else ...[
          pw.Container(
            width: 48,
            height: 48,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.teal, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Center(
              child: pw.Text(
                'AP',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal, fontSize: 16),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ARCH PHARMACY LTD.',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '(WHOLESALERS OF PRESCRIPTION DRUGS)',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '0596549541 / 0534340375',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static Future<Uint8List> generateInvoicePdfBytes(InvoiceRecord invoice) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildHeader(logo),
              pw.SizedBox(height: 16),

              // Title
              pw.Text(
                'INVOICE.',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0),
              ),
              pw.SizedBox(height: 16),

              // Details Grid
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfMetaRow('CUSTOMER', invoice.customerName, labelWidth: 80),
                      _buildPdfMetaRow('ATTENDANT', invoice.attendantName, labelWidth: 80),
                      _buildPdfMetaRow('CASHIER', invoice.cashierName, labelWidth: 80),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfMetaRow('DATE', '${invoice.invoiceDate.year}-${invoice.invoiceDate.month.toString().padLeft(2, '0')}-${invoice.invoiceDate.day.toString().padLeft(2, '0')}', labelWidth: 80),
                      _buildPdfMetaRow('INVOICE #', invoice.invoiceNumber, labelWidth: 80),
                      _buildPdfMetaRow('NO OF PRINT', '${invoice.printCount} Original', labelWidth: 80),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ['Qty', 'Description', 'Unit Price', 'Discount', 'Total'],
                data: invoice.items.map((item) {
                  return [
                    '${item.qty}',
                    item.description,
                    'GHS ${item.unitPrice.toStringAsFixed(2)}',
                    item.discount != null && item.discount! > 0 ? 'GHS ${item.discount!.toStringAsFixed(2)}' : '-',
                    'GHS ${item.lineTotal.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 16),

              // Financial Summary & Status
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Status : ${invoice.status.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: invoice.balance <= 0 ? PdfColors.green800 : PdfColors.orange800)),
                        pw.SizedBox(height: 2),
                        pw.Text('Amount Paid : GHS ${invoice.amountPaid.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.balance > 0) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('Balance Due : GHS ${invoice.balance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                        ],
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Subtotal: GHS ${invoice.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        if (invoice.discount > 0) ...[
                          pw.SizedBox(height: 2),
                          pw.Text('Discount: GHS ${invoice.discount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                        ],
                        pw.SizedBox(height: 4),
                        pw.Text('Grand Total: GHS ${invoice.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.teal900)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Electronic Notice Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                color: PdfColors.grey100,
                child: pw.Center(
                  child: pw.Text(
                    'This is an electronic generated invoice. Thank you for your business!',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printInvoice(InvoiceRecord invoice) async {
    final Uint8List pdfBytes = await generateInvoicePdfBytes(invoice);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<void> printCustomerStatement(CustomerItem customer, [List<InvoiceRecord>? invoices]) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    final statementRows = (invoices != null && invoices.isNotEmpty)
        ? invoices
            .map((i) => [
                  '${i.invoiceDate.year}-${i.invoiceDate.month.toString().padLeft(2, '0')}-${i.invoiceDate.day.toString().padLeft(2, '0')}',
                  i.invoiceNumber,
                  'GHS ${i.grandTotal.toStringAsFixed(2)}',
                  i.status.toUpperCase(),
                ])
            .toList()
        : [
            ['-', 'No recent invoice transactions', 'GHS 0.00', 'CLEAR']
          ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildHeader(logo),
              pw.SizedBox(height: 16),

              pw.Text(
                'CUSTOMER ACCOUNT STATEMENT',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 0.8),
              ),
              pw.SizedBox(height: 16),

              // Customer Info Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfMetaRow('CUSTOMER', customer.businessName, labelWidth: 90),
                      _buildPdfMetaRow('CONTACT', customer.contactPerson, labelWidth: 90),
                      _buildPdfMetaRow('PHONE', customer.phone, labelWidth: 90),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPdfMetaRow('CREDIT LIMIT', 'GHS ${customer.creditLimit.toStringAsFixed(2)}', labelWidth: 100),
                      _buildPdfMetaRow('OUTSTANDING', 'GHS ${customer.outstandingBalance.toStringAsFixed(2)}', labelWidth: 100),
                      _buildPdfMetaRow('AVAIL CREDIT', 'GHS ${customer.availableCredit.toStringAsFixed(2)}', labelWidth: 100),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Recent Account Activities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Type / Ref', 'Amount', 'Status'],
                data: statementRows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                },
              ),
              pw.Spacer(),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                color: PdfColors.grey100,
                child: pw.Center(
                  child: pw.Text(
                    'This statement is generated automatically by ArchPharma ERP',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Statement_${customer.businessName}.pdf',
    );
  }

  static Future<void> printReportsSummary(
    double sales,
    double collected,
    double debt,
    List<ProductItem> products,
  ) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              _buildHeader(logo),
              pw.SizedBox(height: 16),

              pw.Text(
                'EXECUTIVE SALES & INVENTORY ANALYTICS',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 0.8),
              ),
              pw.SizedBox(height: 16),

              // KPI Grid
              pw.TableHelper.fromTextArray(
                headers: ['Total Sales Revenue', 'Cash Collected', 'Outstanding Debt'],
                data: [
                  [
                    'GHS ${sales.toStringAsFixed(2)}',
                    'GHS ${collected.toStringAsFixed(2)}',
                    'GHS ${debt.toStringAsFixed(2)}'
                  ]
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal100),
                cellStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                cellAlignment: pw.Alignment.center,
              ),
              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Medicines Inventory Log Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['Barcode', 'Name', 'Category', 'Stock Level', 'Price'],
                data: products.map((p) => [
                  p.barcode,
                  p.productName,
                  p.category,
                  '${p.currentStock}',
                  'GHS ${p.sellingPrice.toStringAsFixed(2)}'
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Executive_Report.pdf',
    );
  }

  static pw.Widget _buildPdfMetaRow(String label, String value, {double labelWidth = 80}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }
}
