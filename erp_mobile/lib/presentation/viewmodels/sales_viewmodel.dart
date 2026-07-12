import 'package:flutter/material.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/create_sale.dart';
import '../../domain/repositories/sale_repository.dart';

class SalesViewModel extends ChangeNotifier {
  final SaleRepository repository;
  final CreateSale createSale;

  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  SalesViewModel(this.repository, this.createSale);

  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _sales = await repository.getSales();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSale(Sale sale) async {
    await createSale.call(sale);
    await load(); // Recargar la lista
  }
}
