import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saithcommissionshop/data/models/purchase_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class PurchaseProvider extends ChangeNotifier {
  List<PurchaseOrder> _purchases = [];
  bool _isLoaded = false;
  StreamSubscription? _sub;

  List<PurchaseOrder> get purchases => List.unmodifiable(_purchases);
  bool get isLoaded => _isLoaded;

  PurchaseProvider() { _subscribeToFirestore(); }

  void _subscribeToFirestore() {
    _sub = FirebaseService.purchasesStream().listen((snap) {
      _purchases = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        final productsData = (data['products'] as List? ?? []);
        return PurchaseOrder(
          id: d.id,
          supplierId: data['supplierId'] ?? '',
          supplierName: data['supplierName'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          products: productsData.map((p) => PurchaseProduct(
            productId: p['productId'] ?? '',
            name: p['name'] ?? '',
            bags: (p['bags'] as num?)?.toDouble() ?? 0,
            purchasePricePer40kg: (p['purchasePricePer40kg'] as num?)?.toDouble() ?? 0,
            totalCost: (p['totalCost'] as num?)?.toDouble() ?? 0,
          )).toList(),
          totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
          amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
          paymentMethod: data['paymentMethod'] ?? 'cash',
          notes: data['notes'] ?? '',
        );
      }).toList();
      _isLoaded = true;
      notifyListeners();
    }, onError: (_) {
      _isLoaded = true;
      notifyListeners();
    });
  }

  Future<void> addPurchaseOrder(PurchaseOrder order) async {
    await FirebaseService.addPurchase({
      'supplierId': order.supplierId,
      'supplierName': order.supplierName,
      'date': Timestamp.fromDate(order.date),
      'products': order.products.map((p) => {
        'productId': p.productId,
        'name': p.name,
        'bags': p.bags,
        'purchasePricePer40kg': p.purchasePricePer40kg,
        'totalCost': p.totalCost,
      }).toList(),
      'totalAmount': order.totalAmount,
      'amountPaid': order.amountPaid,
      'paymentMethod': order.paymentMethod,
      'notes': order.notes,
    });
  }

  /// Saves the purchase order and applies every item's stock increment,
  /// price update, and history entry as a single atomic write. Prefer this
  /// over addPurchaseOrder() + separate ProductProvider.addStock() calls in
  /// a loop, which can leave a purchase logged with only some items' stock
  /// actually applied if something fails partway through.
  Future<void> addPurchaseOrderWithStock({
    required PurchaseOrder order,
    required String adminId,
  }) async {
    await FirebaseService.savePurchaseTransaction(
      purchaseData: {
        'supplierId': order.supplierId,
        'supplierName': order.supplierName,
        'date': Timestamp.fromDate(order.date),
        'products': order.products.map((p) => {
          'productId': p.productId,
          'name': p.name,
          'bags': p.bags,
          'purchasePricePer40kg': p.purchasePricePer40kg,
          'totalCost': p.totalCost,
        }).toList(),
        'totalAmount': order.totalAmount,
        'amountPaid': order.amountPaid,
        'paymentMethod': order.paymentMethod,
        'notes': order.notes,
      },
      stockAdditions: order.products.map((p) => {
        'productId':         p.productId,
        'changeKg':          p.bags * 40.0,
        'reference':         'PURCHASE',
        'adminId':           adminId,
        'notes':             'Purchase from ${order.supplierName}',
        'lastPurchasePrice': p.purchasePricePer40kg,
      }).toList(),
    );
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
