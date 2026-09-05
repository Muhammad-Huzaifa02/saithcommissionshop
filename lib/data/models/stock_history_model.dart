class StockHistory {
  final String productId;
  final double changeKg;
  final DateTime date;
  final String reference;
  final String adminId;
  final String? notes;

  StockHistory({
    required this.productId,
    required this.changeKg,
    required this.date,
    required this.reference,
    required this.adminId,
    this.notes,
  });

  bool get isDeduction => changeKg < 0;
  bool get isAddition => changeKg > 0;
}
