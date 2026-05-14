import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/product.dart';

/// Product Provider - State Management untuk Product/Barang
class ProductProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper.instance;

  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbHelper.getProducts();
      _products = data.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product?> addProduct(Product product) async {
    try {
      final id = await _dbHelper.insertProduct(product.toMap());
      if (id > 0) {
        await loadProducts();
        return product.copyWith(id: id);
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
    return null;
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final result = await _dbHelper.updateProduct(product.id!, product.toMap());
      if (result > 0) {
        await loadProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final result = await _dbHelper.deleteProduct(id);
      if (result > 0) {
        await loadProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
    return false;
  }

  Future<List<Product>> searchProducts(String keyword) async {
    final data = await _dbHelper.searchProducts(keyword);
    return data.map((map) => Product.fromMap(map)).toList();
  }
}
