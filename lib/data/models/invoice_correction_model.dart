class InvoiceCorrection {
  final String invoiceNo;
  final DateTime correctedAt;
  final String reason;
  final double oldTotal;
  final double newTotal;
  final String correctedBy;

  InvoiceCorrection({
    required this.invoiceNo,
    required this.correctedAt,
    required this.reason,
    required this.oldTotal,
    required this.newTotal,
    this.correctedBy = '',
  });

  double get difference => newTotal - oldTotal;
  bool get isIncrease => difference > 0;

  String get differenceLabel {
    if (difference > 0) return '+PKR ${difference.toStringAsFixed(0)}';
    return '-PKR ${difference.abs().toStringAsFixed(0)}';
  }
}
