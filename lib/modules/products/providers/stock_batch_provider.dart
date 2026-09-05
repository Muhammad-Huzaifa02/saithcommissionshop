import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saithcommissionshop/data/models/stock_batch_model.dart';

// NOTE: This provider is registered in main.dart but not currently used by
// any page — nothing calls loadAll(), addBatch(), or deductStock() yet.
// It's a more accurate (FIFO batch-based) cost-tracking model than the
// single lastPurchasePrice value currently used for COGS in the Profit
// Dashboard and Advanced Analytics. If you want per-batch cost accuracy,
// wiring this in means: (1) recording a StockBatch on every purchase
// instead of/alongside the current stock increment, (2) consuming from the
// oldest active batch(es) on every sale instead of just decrementing
// Product.availableStockKg, and (3) switching COGS calculations to sum
// consumed batch cost instead of lastPurchasePrice. That's a real
// architecture change, not a small wire-up — worth doing deliberately
// rather than as an incidental fix.
class StockBatchProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<StockBatch> _batches = [];
  bool _loading = false;

  List<StockBatch> get batches   => _batches;
  bool             get isLoading => _loading;

  List<StockBatch> forProduct(String productId) =>
      _batches.where((b) => b.productId == productId).toList();

  List<StockBatch> get activeBatches =>
      _batches.where((b) => !b.isExhausted).toList();

  double totalRemainingForProduct(String productId) => forProduct(productId)
      .fold(0.0, (s, b) => s + b.remainingKg);

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('stock_batches')
          .orderBy('purchased_at', descending: true)
          .get();
      _batches = snap.docs.map(StockBatch.fromDoc).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addBatch(StockBatch batch) async {
    try {
      final ref = await _db.collection('stock_batches').add(batch.toMap());
      _batches.insert(0, StockBatch(
        id: ref.id, productId: batch.productId,
        productName: batch.productName, supplierId: batch.supplierId,
        supplierName: batch.supplierName,
        purchaseRatePerKg: batch.purchaseRatePerKg,
        totalKg: batch.totalKg, remainingKg: batch.remainingKg,
        purchasedAt: batch.purchasedAt, notes: batch.notes,
      ));
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deductStock(String batchId, double kg) async {
    final i = _batches.indexWhere((b) => b.id == batchId);
    if (i < 0) return false;
    try {
      await _db.collection('stock_batches')
          .doc(batchId).update({'remaining_kg': FieldValue.increment(-kg)});
      final b = _batches[i];
      _batches[i] = StockBatch(
        id: b.id, productId: b.productId, productName: b.productName,
        supplierId: b.supplierId, supplierName: b.supplierName,
        purchaseRatePerKg: b.purchaseRatePerKg, totalKg: b.totalKg,
        remainingKg: (b.remainingKg - kg).clamp(0, double.infinity),
        purchasedAt: b.purchasedAt, notes: b.notes,
      );
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }
}
