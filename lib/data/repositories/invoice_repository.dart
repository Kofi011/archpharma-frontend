import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasource/api_client.dart';
import '../../features/auth/auth_provider.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceRecord>> getInvoices();
  Future<void> addInvoice(InvoiceRecord invoice);
  Future<void> updateInvoice(InvoiceRecord invoice);
  Future<void> deleteInvoice(String invoiceId);
  Future<void> clearAll();
  Future<void> resetToDefaults();
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  static const String _storageKey = 'archpharma_invoices_db';
  final ApiClient? _apiClient;

  InvoiceRepositoryImpl([this._apiClient]);

  List<InvoiceRecord>? _cachedInvoices;

  Future<void> _saveToStorage(List<InvoiceRecord> items) async {
    _cachedInvoices = List.from(items);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((i) => i.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  @override
  Future<List<InvoiceRecord>> getInvoices() async {
    // 1. Fetch fresh invoices from cloud API if online
    if (_apiClient != null) {
      try {
        final res = await _apiClient!.dio.get('/invoices');
        if (res.statusCode == 200 && res.data is List) {
          final cloudList = (res.data as List).map((json) {
            final map = json as Map<String, dynamic>;
            final itemsList = (map['items'] as List?)?.map((i) {
              final itemMap = i as Map<String, dynamic>;
              return InvoiceItemLine(
                id: itemMap['id']?.toString() ?? '',
                productId: itemMap['productId']?.toString() ?? '',
                description: itemMap['description']?.toString() ?? 'Medicine Item',
                qty: (itemMap['qty'] as num?)?.toInt() ?? 1,
                unitPrice: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
                discount: (itemMap['discount'] as num?)?.toDouble() ?? 0.0,
                lineTotal: (itemMap['lineTotal'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList() ?? [];

            return InvoiceRecord(
              id: map['id']?.toString() ?? '',
              invoiceNumber: map['invoiceNumber']?.toString() ?? '',
              customerId: map['customerId']?.toString() ?? '',
              customerName: map['customerName']?.toString() ?? 'Customer',
              cashierName: map['cashierName']?.toString() ?? 'Cashier',
              attendantName: map['attendantName']?.toString() ?? 'Attendant',
              invoiceDate: map['invoiceDate'] != null ? DateTime.tryParse(map['invoiceDate'].toString()) ?? DateTime.now() : DateTime.now(),
              subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
              discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
              vat: (map['vat'] as num?)?.toDouble() ?? 0.0,
              grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
              amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
              balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
              status: map['status']?.toString() ?? 'paid',
              printCount: (map['printCount'] as num?)?.toInt() ?? 1,
              items: itemsList,
              syncStatus: 'synced',
            );
          }).toList();
          await _saveToStorage(cloudList);
          return List.from(cloudList);
        }
      } catch (_) {}
    }

    if (_cachedInvoices != null) {
      return List.from(_cachedInvoices!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _cachedInvoices = decoded
            .map((item) => InvoiceRecord.fromJson(item as Map<String, dynamic>))
            .toList();
        return List.from(_cachedInvoices!);
      }
    } catch (_) {}

    _cachedInvoices = [];
    await _saveToStorage(_cachedInvoices!);
    return List.from(_cachedInvoices!);
  }

  @override
  Future<void> addInvoice(InvoiceRecord invoice) async {
    final list = await getInvoices();
    list.removeWhere((i) => i.id == invoice.id);
    list.insert(0, invoice);
    await _saveToStorage(list);

    if (_apiClient != null) {
      try {
        await _apiClient!.dio.post('/invoices', data: {
          'id': invoice.id,
          'invoiceNumber': invoice.invoiceNumber,
          'customerId': invoice.customerId,
          'customerName': invoice.customerName,
          'cashierName': invoice.cashierName,
          'attendantName': invoice.attendantName,
          'subtotal': invoice.subtotal,
          'discount': invoice.discount,
          'vat': invoice.vat,
          'grandTotal': invoice.grandTotal,
          'amountPaid': invoice.amountPaid,
          'balance': invoice.balance,
          'status': invoice.status,
          'items': invoice.items.map((i) => {
            'id': i.id,
            'productId': i.productId,
            'description': i.description,
            'qty': i.qty,
            'unitPrice': i.unitPrice,
            'discount': i.discount,
            'lineTotal': i.lineTotal,
          }).toList(),
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> updateInvoice(InvoiceRecord invoice) async {
    final list = await getInvoices();
    final index = list.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      list[index] = invoice;
    } else {
      list.insert(0, invoice);
    }
    await _saveToStorage(list);
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    final list = await getInvoices();
    list.removeWhere((i) => i.id == invoiceId);
    await _saveToStorage(list);
  }

  @override
  Future<void> clearAll() async {
    _cachedInvoices = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode([]));
    } catch (_) {}
  }

  @override
  Future<void> resetToDefaults() async {
    _cachedInvoices = [];
    await _saveToStorage(_cachedInvoices!);
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InvoiceRepositoryImpl(apiClient);
});
