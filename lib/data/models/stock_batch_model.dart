import 'package:cloud_firestore/cloud_firestore.dart';

class StockBatch {
  final String   id;
  final String   productId;
  final String   productName;
  final String   supplierId;
  final String   supplierName;
  final double   purchaseRatePerKg;
  final double   totalKg;
  final double   remainingKg;
  final DateTime purchasedAt;
  final String   notes;

  StockBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.supplierId,
    required this.supplierName,
    required this.purchaseRatePerKg,
    required this.totalKg,
    required this.remainingKg,
    required this.purchasedAt,
    this.notes = '',
  });

  double get usedKg     => totalKg - remainingKg;
  double get usedPct    => totalKg == 0 ? 0 : usedKg / totalKg;
  double get totalCost  => totalKg * purchaseRatePerKg;
  bool   get isExhausted => remainingKg <= 0;

  Map<String, dynamic> toMap() => {
    'product_id':          productId,
    'product_name':        productName,
    'supplier_id':         supplierId,
    'supplier_name':       supplierName,
    'purchase_rate_per_kg':purchaseRatePerKg,
    'total_kg':            totalKg,
    'remaining_kg':        remainingKg,
    'purchased_at':        Timestamp.fromDate(purchasedAt),
    'notes':               notes,
  };

  factory StockBatch.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StockBatch(
      id:                 doc.id,
      productId:          d['product_id']           ?? '',
      productName:        d['product_name']          ?? '',
      supplierId:         d['supplier_id']           ?? '',
      supplierName:       d['supplier_name']         ?? '',
      purchaseRatePerKg:  (d['purchase_rate_per_kg'] as num? ?? 0).toDouble(),
      totalKg:            (d['total_kg']             as num? ?? 0).toDouble(),
      remainingKg:        (d['remaining_kg']         as num? ?? 0).toDouble(),
      purchasedAt:        (d['purchased_at'] as Timestamp).toDate(),
      notes:              d['notes']                 ?? '',
    );
  }
}
