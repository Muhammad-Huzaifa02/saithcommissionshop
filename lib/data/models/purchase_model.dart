class PurchaseOrder {
  final String id;
  final String supplierId;
  final String supplierName;
  final DateTime date;
  final List<PurchaseProduct> products;
  final double totalAmount;
  final double amountPaid;
  final String paymentMethod;
  final String notes;

  PurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.date,
    required this.products,
    required this.totalAmount,
    required this.amountPaid,
    required this.paymentMethod,
    this.notes = '',
  });

  bool get isFullyPaid => amountPaid >= totalAmount;
  double get balance => totalAmount - amountPaid;
}

class PurchaseProduct {
  final String productId;
  final String name;
  final double bags;
  final double purchasePricePer40kg;
  final double totalCost;

  PurchaseProduct({
    required this.productId,
    required this.name,
    required this.bags,
    required this.purchasePricePer40kg,
    required this.totalCost,
  });

  double get totalWeightKg => bags * 40;
}
