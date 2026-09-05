class ReminderModel {
  final String customerId;
  final String name;
  final String phone;
  final double amount;
  final DateTime dateTime;

  ReminderModel({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.amount,
    required this.dateTime,
  });
}