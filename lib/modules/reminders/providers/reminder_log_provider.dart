import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saithcommissionshop/data/models/reminder_log_model.dart';

class ReminderLogProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  List<ReminderLog> _logs = [];
  bool _loading = false;

  List<ReminderLog> get logs    => _logs;
  bool             get isLoading => _loading;

  int get sentCount   => _logs.where((l) => l.status == 'sent').length;
  int get paidCount   => _logs.where((l) => l.status == 'paid').length;
  double get totalReminded =>
      _logs.fold(0.0, (s, l) => s + l.pendingAmount);

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('reminder_logs')
          .orderBy('sent_at', descending: true)
          .limit(100)
          .get();
      _logs = snap.docs.map(ReminderLog.fromDoc).toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> logReminder(ReminderLog log) async {
    try {
      final ref = await _db.collection('reminder_logs').add(log.toMap());
      _logs.insert(0, ReminderLog(
        id: ref.id, customerId: log.customerId,
        customerName: log.customerName, customerPhone: log.customerPhone,
        pendingAmount: log.pendingAmount, channel: log.channel,
        status: log.status, message: log.message,
        sentBy: log.sentBy, sentAt: log.sentAt,
      ));
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _db.collection('reminder_logs')
          .doc(id).update({'status': status});
      final i = _logs.indexWhere((l) => l.id == id);
      if (i >= 0) {
        final l = _logs[i];
        _logs[i] = ReminderLog(
          id: l.id, customerId: l.customerId,
          customerName: l.customerName, customerPhone: l.customerPhone,
          pendingAmount: l.pendingAmount, channel: l.channel,
          status: status, message: l.message,
          sentBy: l.sentBy, sentAt: l.sentAt,
        );
        notifyListeners();
      }
      return true;
    } catch (_) { return false; }
  }
}
