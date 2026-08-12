import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    // First run on fresh device: start clean with 0 invoices
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
  return InvoiceRepositoryImpl();
});
