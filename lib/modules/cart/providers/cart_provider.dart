import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';

class CartProvider extends ChangeNotifier {
  final List<InvoiceProduct> _items = [];

  List<InvoiceProduct> get items     => List.unmodifiable(_items);
  int    get itemCount  => _items.fold(0, (s, i) => s + i.quantity.toInt());
  double get totalPrice => _items.fold(0.0, (s, i) => s + i.totalPrice);

  void addProduct(InvoiceProduct product) {
    final idx = (product.productId != null && product.productId!.isNotEmpty)
        ? _items.indexWhere((i) => i.productId == product.productId)
        : _items.indexWhere((i) => i.name == product.name);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(
        quantity: _items[idx].quantity + product.quantity,
      );
    } else {
      _items.add(product);
    }
    notifyListeners();
  }

  void increaseQty(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = _items[index].copyWith(
      quantity: _items[index].quantity + 1,
    );
    notifyListeners();
  }

  void decreaseQty(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity - 1,
      );
    }
    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void insertAt(int index, InvoiceProduct item) {
    if (index >= 0 && index <= _items.length) {
      _items.insert(index, item);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
