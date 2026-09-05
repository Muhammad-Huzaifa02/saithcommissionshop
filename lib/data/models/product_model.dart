class Product {
  final String id;
  final String name;
  final double pricePer40kg;
  final double availableStockKg;
  final double lastPurchasePrice;
  final double averagePurchasePrice;
  final String? category;
  final double reorderPointKg;

  const Product({
    required this.id,
    required this.name,
    required this.pricePer40kg,
    required this.availableStockKg,
    this.lastPurchasePrice = 0,
    this.averagePurchasePrice = 0,
    this.category = 'Rice',
    this.reorderPointKg = 200,
  });

  bool get isLowStock   => availableStockKg <= reorderPointKg;
  bool get isOutOfStock => availableStockKg <= 0;
  double get stockBags  => availableStockKg / 40;
  double get stockValue => stockBags * pricePer40kg;
  double get stockCost  => stockBags * averagePurchasePrice;
  double get profitPotential => stockValue - stockCost;
  String get displayName => name;

  Product deductStock(double usedKg) {
    final newStock = availableStockKg - usedKg;
    if (newStock < 0) throw Exception('$name: Insufficient stock');
    return copyWith(availableStockKg: newStock);
  }

  Product addStock(double addedKg) =>
      copyWith(availableStockKg: availableStockKg + addedKg);

  Product copyWith({
    double? pricePer40kg,
    double? availableStockKg,
    double? lastPurchasePrice,
    double? averagePurchasePrice,
    String? category,
    double? reorderPointKg,
  }) {
    return Product(
      id: id,
      name: name,
      pricePer40kg: pricePer40kg ?? this.pricePer40kg,
      availableStockKg: availableStockKg ?? this.availableStockKg,
      lastPurchasePrice: lastPurchasePrice ?? this.lastPurchasePrice,
      averagePurchasePrice: averagePurchasePrice ?? this.averagePurchasePrice,
      category: category ?? this.category,
      reorderPointKg: reorderPointKg ?? this.reorderPointKg,
    );
  }
}
