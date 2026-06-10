import 'package:flutter/material.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/usecases/create_purchase.dart';
import '../../domain/repositories/purchase_repository.dart';

class PurchasesViewModel extends ChangeNotifier {
  final PurchaseRepository repository;
  final CreatePurchase createPurchase;

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  String? _error;

  PurchasesViewModel(this.repository, this.createPurchase);

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _purchases = await repository.getPurchases();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPurchase(Purchase purchase) async {
    await createPurchase.call(purchase);
    await load(); // Recargar la lista
  }
}
