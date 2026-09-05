import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/ledger_entry.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class LedgerProvider extends ChangeNotifier {
  final Map<String, List<LedgerEntry>> _entriesByCustomer = {};
  final Map<String, StreamSubscription> _subs = {};

  List<LedgerEntry> get entries =>
      _entriesByCustomer.values.expand((e) => e).toList();

  // ── Subscribe for a specific customer ────────────────────────────────────
  void subscribeForCustomer(String customerId) {
    if (_subs.containsKey(customerId)) {
      return; // already subscribed
    }
    debugPrint('Subscribing to Ledger for customer: $customerId');

    _subs[customerId] = FirebaseService.customerLedgerStream(customerId)
        .listen((snap) {
      debugPrint('Ledger Stream updated for $customerId: ${snap.docs.length} docs');
      final list = snap.docs.map((d) {
        try {
          final data = d.data() as Map<String, dynamic>;
          return LedgerEntry(
            id:          d.id,
            customerId:  data['customerId']  as String? ?? customerId,
            type:        LedgerType.values.firstWhere(
                    (t) => t.name == (data['type'] as String?),
                orElse: () => LedgerType.invoice),
            debit:       (data['debit']      as num?)?.toDouble() ?? 0,
            credit:      (data['credit']     as num?)?.toDouble() ?? 0,
            balance:     (data['balance']    as num?)?.toDouble() ?? 0,
            description: data['description'] as String? ?? '',
            dateTime: data['dateTime'] != null
                ? (data['dateTime'] as Timestamp).toDate()
                : DateTime.now(),
            invoiceNo: data['invoiceNo']  as String?,
          );
        } catch (e) {
          debugPrint('Error parsing ledger entry ${d.id}: $e');
          return null;
        }
      }).whereType<LedgerEntry>().toList();
      
      // Sort locally
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      
      _entriesByCustomer[customerId] = list;
      notifyListeners();
    }, onError: (err) {
      debugPrint('Ledger Stream Error for $customerId: $err');
    });
  }

  List<LedgerEntry> entriesForCustomer(String customerId) {
    subscribeForCustomer(customerId);
    return _entriesByCustomer[customerId] ?? [];
  }

  void unsubscribeCustomer(String customerId) {
    _subs[customerId]?.cancel();
    _subs.remove(customerId);
    _entriesByCustomer.remove(customerId);
  }

  double customerBalance(String customerId) =>
      entriesForCustomer(customerId)
          .fold(0.0, (s, e) => s + e.debit - e.credit);

  Future<void> addEntry(LedgerEntry entry) =>
      FirebaseService.addLedgerEntry({
        'customerId':  entry.customerId,
        'type':        entry.type.name,
        'debit':       entry.debit,
        'credit':      entry.credit,
        'balance':     entry.balance,
        'description': entry.description,
        'invoiceNo':   entry.invoiceNo,
      });

  Future<void> addPayment({
    required String customerId,
    required double amount,
    required String description,
    String? invoiceNo,
  }) async {
    final currentBal = customerBalance(customerId);
    await FirebaseService.addLedgerEntry({
      'customerId':  customerId,
      'type':        LedgerType.payment.name,
      'debit':       0,
      'credit':      amount,
      'balance':     (currentBal - amount).clamp(0, double.infinity),
      'description': description,
      'invoiceNo':   invoiceNo,
    });
  }

  @override
  void dispose() {
    for (final sub in _subs.values) sub.cancel();
    super.dispose();
  }
}
