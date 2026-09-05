import 'package:flutter/material.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';

/// Tracks invoice history — edits, voids, and corrections — separately
/// from the live InvoiceProvider so the audit trail is never lost.
class InvoiceHistoryProvider extends ChangeNotifier {
  final List<_HistoryEntry> _history = [];

  List<_HistoryEntry> get history => List.unmodifiable(_history);

  int get totalEdits  => _history.where((h) => h.action == _Action.edit).length;
  int get totalVoids  => _history.where((h) => h.action == _Action.void_).length;

  // ── Record actions ────────────────────────────────────────────────────────
  void recordEdit({
    required InvoiceData original,
    required InvoiceData updated,
    required String reason,
    required String editedBy,
  }) {
    _history.insert(0, _HistoryEntry(
      action:      _Action.edit,
      invoiceNo:   original.invoiceNo,
      description: 'Edited by $editedBy — $reason',
      oldTotal:    original.grandTotal,
      newTotal:    updated.grandTotal,
      performedBy: editedBy,
      timestamp:   DateTime.now(),
    ));
    notifyListeners();
  }

  void recordVoid({
    required InvoiceData invoice,
    required String reason,
    required String voidedBy,
  }) {
    _history.insert(0, _HistoryEntry(
      action:      _Action.void_,
      invoiceNo:   invoice.invoiceNo,
      description: 'Voided by $voidedBy — $reason',
      oldTotal:    invoice.grandTotal,
      newTotal:    0,
      performedBy: voidedBy,
      timestamp:   DateTime.now(),
    ));
    notifyListeners();
  }

  void recordPayment({
    required String invoiceNo,
    required double amount,
    required String recordedBy,
  }) {
    _history.insert(0, _HistoryEntry(
      action:      _Action.payment,
      invoiceNo:   invoiceNo,
      description: 'Payment of PKR ${amount.toStringAsFixed(0)} recorded by $recordedBy',
      oldTotal:    0,
      newTotal:    amount,
      performedBy: recordedBy,
      timestamp:   DateTime.now(),
    ));
    notifyListeners();
  }

  // ── Query ─────────────────────────────────────────────────────────────────
  List<_HistoryEntry> historyForInvoice(String invoiceNo) =>
      _history.where((h) => h.invoiceNo == invoiceNo).toList();

  void clear() {
    _history.clear();
    notifyListeners();
  }
}

enum _Action { edit, void_, payment }

class _HistoryEntry {
  final _Action  action;
  final String   invoiceNo;
  final String   description;
  final double   oldTotal;
  final double   newTotal;
  final String   performedBy;
  final DateTime timestamp;

  _HistoryEntry({
    required this.action,
    required this.invoiceNo,
    required this.description,
    required this.oldTotal,
    required this.newTotal,
    required this.performedBy,
    required this.timestamp,
  });

  double get difference => newTotal - oldTotal;

  String get actionLabel {
    switch (action) {
      case _Action.edit:    return 'Edited';
      case _Action.void_:   return 'Voided';
      case _Action.payment: return 'Payment';
    }
  }
}
