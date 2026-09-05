import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoaded = false;
  StreamSubscription? _sub;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoaded => _isLoaded;
  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock && !p.isOutOfStock).toList();
  List<Product> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();
  int get healthyCount => _products.where((p) => !p.isLowStock).length;
  int get lowStockCount => lowStockProducts.length;
  int get outOfStockCount => outOfStockProducts.length;
  double get totalStockValue => _products.fold(0.0, (s, p) => s + p.stockValue);

  ProductProvider() {
    _subscribeToFirestore();
  }

  void _subscribeToFirestore() {
    _sub = FirebaseService.productsStream().listen((snap) {
      _products = snap.docs.map((d) => _fromFirestore(d)).toList();
      _isLoaded = true;
      notifyListeners();
    }, onError: (_) {
      _isLoaded = true;
      notifyListeners();
    });
  }

  static Product _fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: d['name'] as String? ?? '',
      pricePer40kg: (d['pricePer40kg'] as num?)?.toDouble() ?? 0,
      availableStockKg: (d['availableStockKg'] as num?)?.toDouble() ?? 0,
      lastPurchasePrice: (d['lastPurchasePrice'] as num?)?.toDouble() ?? 0,
      averagePurchasePrice: (d['averagePurchasePrice'] as num?)?.toDouble() ?? 0,
      category: d['category'] as String? ?? 'Rice',
      reorderPointKg: (d['reorderPointKg'] as num?)?.toDouble() ?? 200,
    );
  }

  static Map<String, dynamic> _toFirestore(Product p) => {
        'name': p.name,
        'pricePer40kg': p.pricePer40kg,
        'availableStockKg': p.availableStockKg,
        'lastPurchasePrice': p.lastPurchasePrice,
        'averagePurchasePrice': p.averagePurchasePrice,
        'category': p.category ?? 'Rice',
        'reorderPointKg': p.reorderPointKg,
      };

  Future<void> addProduct(Product product) => FirebaseService.addProduct(_toFirestore(product));

  Future<void> updateProduct(String id, Product updated) => FirebaseService.updateProduct(id, _toFirestore(updated));

  Future<void> updatePrice(String id, double newPrice) async {
    final product = getProductById(id);
    if (product == null) return;
    final updated = product.copyWith(pricePer40kg: newPrice);
    await updateProduct(id, updated);
  }

  Future<void> deleteProduct(String id) => FirebaseService.deleteProduct(id);

  Future<void> addStock({
    required String productId,
    required double addedKg,
    required String reference,
    required String adminId,
    String? notes,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;

    await FirebaseService.adjustStock(productId, addedKg);

    await FirebaseService.addStockHistory({
      'productId': productId,
      'changeKg': addedKg,
      'reference': reference,
      'adminId': adminId,
      'notes': notes,
    });
    // Local `_products` list updates via the Firestore stream listener
    // above, so no manual notifyListeners() is needed here.
  }

  Future<void> deductStock({
    required String productId,
    required double usedKg,
    required String invoiceNo,
    required String adminId,
  }) async {
    final product = getProductById(productId);
    if (product == null) return;

    await FirebaseService.adjustStock(productId, -usedKg);

    await FirebaseService.addStockHistory({
      'productId': productId,
      'changeKg': -usedKg,
      'reference': invoiceNo,
      'adminId': adminId,
      'notes': 'Deducted via Invoice $invoiceNo',
    });
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? getProductByName(String name) {
    try {
      return _products.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  List<Product> searchProducts(String query) {
    final q = query.toLowerCase();
    return _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
