import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomersNotifier extends StateNotifier<List<CustomerItem>> {
  final CustomerRepository _repository;

  CustomersNotifier(this._repository) : super([]) {
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _repository.getCustomers();
    state = customers;
  }

  Future<void> addCustomer(CustomerItem customer) async {
    await _repository.addCustomer(customer);
    await _loadCustomers();
  }

  Future<void> updateCustomer(CustomerItem customer) async {
    await _repository.updateCustomer(customer);
    await _loadCustomers();
  }

  Future<void> updateCreditLimit(String id, double newLimit) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = state[index];
      final updated = old.copyWith(creditLimit: newLimit);
      await _repository.updateCustomer(updated);
      await _loadCustomers();
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _repository.deleteCustomer(id);
    await _loadCustomers();
  }

  Future<void> clearAllCustomers() async {
    await _repository.clearAll();
    state = [];
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    await _loadCustomers();
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, List<CustomerItem>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomersNotifier(repository);
});
