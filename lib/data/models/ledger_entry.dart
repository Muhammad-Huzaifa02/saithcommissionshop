enum LedgerType { invoice, payment, adjustment }

class LedgerEntry {
  final String id;
  final String customerId;
  final LedgerType type;
  final double debit;
  final double credit;
  final double balance;
  final String description;
  final DateTime dateTime;
  final String? invoiceNo;

  // Legacy aliases
  String get reference  => invoiceNo ?? id;
  DateTime get date     => dateTime;

  LedgerEntry({
    String? id,
    required this.customerId,
    required this.type,
    required this.debit,
    required this.credit,
    required this.balance,
    String? description,
    DateTime? dateTime,
    this.invoiceNo,
    // Legacy params
    String? reference,
    DateTime? date,
  })  : id          = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        description = description ?? reference ?? '',
        dateTime    = dateTime ?? date ?? DateTime.now();
}
