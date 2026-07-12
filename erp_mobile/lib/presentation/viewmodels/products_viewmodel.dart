import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/create_product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductsViewModel extends ChangeNotifier {
  final ProductRepository repository;
  final CreateProduct createProduct;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  ProductsViewModel(this.repository, this.createProduct);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await repository.getProducts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    await createProduct.call(product);
    await load(); // Recargar la lista
  }
}
