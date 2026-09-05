class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime dateTime;
  final String method;
  final String? reference;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.dateTime,
    this.method = 'cash',
    this.reference,
  });
}
