import 'package:flutter/foundation.dart';

class ReminderRecord {
  final String name;
  final String phone;
  final double amount;
  final DateTime time;

  ReminderRecord({
    required this.name,
    required this.phone,
    required this.amount,
    required this.time,
  });
}

class ReminderProvider extends ChangeNotifier {
  final List<ReminderRecord> _history = [];

  List<ReminderRecord> get history => _history;

  void add(ReminderRecord r) {
    _history.add(r);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }
}
