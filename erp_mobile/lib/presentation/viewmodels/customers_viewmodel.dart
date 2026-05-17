import 'package:flutter/material.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customers.dart';

class CustomersViewModel extends ChangeNotifier {
  final GetCustomers getCustomers;
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  CustomersViewModel(this.getCustomers);

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _customers = await getCustomers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
