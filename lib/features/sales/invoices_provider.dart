import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';

class InvoicesNotifier extends StateNotifier<List<InvoiceRecord>> {
  final InvoiceRepository _repository;

  InvoicesNotifier(this._repository) : super([]) {
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final invoices = await _repository.getInvoices();
    state = invoices;
  }

  Future<void> addInvoice(InvoiceRecord invoice) async {
    await _repository.addInvoice(invoice);
    await _loadInvoices();
  }

  Future<void> recordPayment(String invoiceId, double paymentAmount) async {
    final invIndex = state.indexWhere((inv) => inv.id == invoiceId);
    if (invIndex != -1) {
      final old = state[invIndex];
      final updated = _calculatePaidInvoice(old, paymentAmount);
      await _repository.updateInvoice(updated);
      await _loadInvoices();
    }
  }

  InvoiceRecord _calculatePaidInvoice(InvoiceRecord inv, double paymentAmount) {
    final newPaid = inv.amountPaid + paymentAmount;
    final newBalance = (inv.grandTotal - newPaid).clamp(0.0, double.infinity);
    final newStatus = newBalance <= 0 ? 'paid' : 'partial';

    return InvoiceRecord(
      id: inv.id,
      invoiceNumber: inv.invoiceNumber,
      customerId: inv.customerId,
      customerName: inv.customerName,
      cashierName: inv.cashierName,
      attendantName: inv.attendantName,
      invoiceDate: inv.invoiceDate,
      subtotal: inv.subtotal,
      discount: inv.discount,
      vat: inv.vat,
      grandTotal: inv.grandTotal,
      amountPaid: newPaid,
      balance: newBalance,
      status: newStatus,
      printCount: inv.printCount,
      items: inv.items,
      syncStatus: 'pending',
    );
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await _repository.deleteInvoice(invoiceId);
    await _loadInvoices();
  }

  Future<void> clearAllInvoices() async {
    await _repository.clearAll();
    state = [];
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    await _loadInvoices();
  }
}

final invoicesProvider = StateNotifierProvider<InvoicesNotifier, List<InvoiceRecord>>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoicesNotifier(repository);
});
