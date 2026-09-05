import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class InvoiceProvider extends ChangeNotifier {
  List<InvoiceData> _invoices = [];
  bool              _isLoaded = false;
  StreamSubscription? _sub;
  String? _currentSubscriptionId;

  List<InvoiceData> get invoices          => List.unmodifiable(_invoices);
  bool              get isLoaded          => _isLoaded;

  String get nextInvoiceNo {
    final now = DateTime.now();
    final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final count = _invoices.length + 1;
    // Format: INV-20240804-001
    return 'INV-$datePart-${count.toString().padLeft(3, '0')}';
  }

  int    get totalInvoiceCount => _invoices.length;
  double get totalSales   => _invoices.fold(0.0, (s, i) => s + i.grandTotal);
  double get totalPaid    => _invoices.where((i) =>  i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);
  double get totalPending => _invoices.where((i) => !i.isPaid).fold(0.0, (s, i) => s + (i.grandTotal - i.amountPaid));
  int    get pendingCount => _invoices.where((i) => !i.isPaid).length;

  InvoiceProvider() { 
    // We will initialize subscription when the user is known
  }

  void initialize(String? customerId, bool isAdmin) {
    final subId = '${customerId ?? "guest"}_$isAdmin';
    if (_currentSubscriptionId == subId) return;
    
    _sub?.cancel();
    _currentSubscriptionId = subId;
    _isLoaded = false;

    Stream<QuerySnapshot> stream;
    if (isAdmin) {
      stream = FirebaseService.invoicesStream();
    } else if (customerId != null) {
      stream = FirebaseService.customerInvoicesStream(customerId);
    } else {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    _sub = stream.listen((snap) {
      debugPrint('Invoice Stream updated for $subId: ${snap.docs.length} docs');
      final list = snap.docs.map((d) {
        try { return _fromFirestore(d); }
        catch (e) { return null; }
      }).whereType<InvoiceData>().toList();
      
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _invoices = list;
      _isLoaded = true;
      notifyListeners();
    }, onError: (err) {
      debugPrint('Invoice Stream Error for $subId: $err');
      _isLoaded = true;
      notifyListeners();
    });
  }

  // ── Model conversion ──────────────────────────────────────────────────────
  static InvoiceData _fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InvoiceData(
      invoiceNo:        doc.id,
      customerId:       d['customerId']       as String? ?? '',
      customerName:     d['customerName']     as String? ?? '',
      customerPhone:    d['customerPhone']    as String? ?? '',
      customerDisplayId: d['customerDisplayId'] as String?,
      dateTime:         d['dateTime'] != null
          ? (d['dateTime'] as Timestamp).toDate()
          : DateTime.now(),
      products: ((d['products'] as List?) ?? []).map((p) => InvoiceProduct(
        name:          p['name']         as String? ?? '',
        productId:     p['productId']    as String?,
        pricePer40kg:  (p['pricePer40kg'] as num?)?.toDouble() ?? 0,
        quantity:      (p['quantity']     as num?)?.toDouble() ?? 0,
        weightPerUnit: (p['weightPerUnit'] as num?)?.toDouble() ?? 0,
        bags50:        (p['bags50']        as num?)?.toInt() ?? 0,
        bags100:       (p['bags100']       as num?)?.toInt() ?? 0,
        looseWeightKg: (p['looseWeightKg'] as num?)?.toDouble() ?? 0,
      )).toList(),
      paymentMethod:    d['paymentMethod']    as String? ?? 'cash',
      isPaid:           d['isPaid']           as bool?   ?? false,
      notes:            d['notes']            as String? ?? '',
      gstPercent:       (d['gstPercent']      as num?)?.toDouble() ?? 0,
      discountPercent:  (d['discountPercent'] as num?)?.toDouble() ?? 0,
      manualDiscount:   (d['manualDiscount']  as num?)?.toDouble() ?? 0,
      commissionPercent:(d['commissionPercent'] as num?)?.toDouble() ?? 0,
      fixedCommission:  (d['fixedCommission'] as num?)?.toDouble() ?? 0,
      laborCharges:     (d['laborCharges']    as num?)?.toDouble() ?? 0,
      packingCharges:   (d['packingCharges']  as num?)?.toDouble() ?? 0,
      transportCharges: (d['transportCharges'] as num?)?.toDouble() ?? 0,
      otherCharges:     (d['otherCharges']    as num?)?.toDouble() ?? 0,
      amountPaid:       (d['amountPaid']      as num?)?.toDouble() ?? 0,
    );
  }

  static Map<String, dynamic> _toFirestore(InvoiceData inv) => {
    'customerId':       inv.customerId,
    'customerName':     inv.customerName,
    'customerPhone':    inv.customerPhone,
    'customerDisplayId': inv.customerDisplayId,
    'dateTime':         Timestamp.fromDate(inv.dateTime),
    'products': inv.products.map((p) => {
      'name':          p.name,
      'pricePer40kg':  p.pricePer40kg,
      'quantity':      p.quantity,
      'weightPerUnit': p.weightPerUnit,
    }).toList(),
    'paymentMethod':    inv.paymentMethod,
    'isPaid':           inv.isPaid,
    'notes':            inv.notes,
    'grandTotal':       inv.grandTotal,
    'subtotal':         inv.subtotal,
    'gstPercent':       inv.gstPercent,
    'discountPercent':  inv.discountPercent,
    'manualDiscount':   inv.manualDiscount,
    'commissionPercent':inv.commissionPercent,
    'fixedCommission':  inv.fixedCommission,
    'laborCharges':     inv.laborCharges,
    'packingCharges':   inv.packingCharges,
    'transportCharges': inv.transportCharges,
    'otherCharges':     inv.otherCharges,
    'amountPaid':       inv.amountPaid,
  };

  // ── Customer stats ────────────────────────────────────────────────────────
  List<InvoiceData> invoicesByCustomer(String customerId) =>
      _invoices.where((i) => i.customerId == customerId).toList();

  double customerTotalSpent(String customerId) =>
      invoicesByCustomer(customerId).fold(0.0, (s, i) => s + i.grandTotal);

  double customerBalance(String customerId) =>
      invoicesByCustomer(customerId)
          .where((i) => !i.isPaid)
          .fold(0.0, (s, i) => s + (i.grandTotal - i.amountPaid));

  int customerOrderCount(String customerId)   => invoicesByCustomer(customerId).length;
  int customerPendingCount(String customerId) =>
      invoicesByCustomer(customerId).where((i) => !i.isPaid).length;

  List<Map<String, dynamic>> get customerSummaries {
    final map = <String, Map<String, dynamic>>{};
    for (final inv in _invoices) {
      if (!map.containsKey(inv.customerId)) {
        map[inv.customerId] = {
          'id': inv.customerId, 'name': inv.customerName,
          'phone': inv.customerPhone, 'total': 0.0,
          'paid': 0.0, 'pending': 0.0, 'count': 0,
          'lastOrder': inv.dateTime,
        };
      }
      map[inv.customerId]!['total']   = (map[inv.customerId]!['total']   as double) + inv.grandTotal;
      map[inv.customerId]!['paid']    = (map[inv.customerId]!['paid']    as double) + inv.amountPaid;
      map[inv.customerId]!['pending'] = (map[inv.customerId]!['pending'] as double) + (inv.grandTotal - inv.amountPaid);
      map[inv.customerId]!['count']   = (map[inv.customerId]!['count']   as int)    + 1;
    }
    return map.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }

  Map<int, double> get monthlySales {
    final map = <int, double>{};
    for (final inv in _invoices) {
      final m = inv.dateTime.month;
      map[m] = (map[m] ?? 0) + inv.grandTotal;
    }
    return map;
  }

  double dailyTotal([DateTime? date]) {
    final d = date ?? DateTime.now();
    return _invoices
        .where((i) => i.dateTime.year == d.year &&
        i.dateTime.month == d.month &&
        i.dateTime.day   == d.day)
        .fold(0.0, (s, i) => s + i.grandTotal);
  }

  List<InvoiceData> todaysInvoices()  {
    final now = DateTime.now();
    return _invoices.where((i) =>
    i.dateTime.year  == now.year  &&
        i.dateTime.month == now.month &&
        i.dateTime.day   == now.day).toList();
  }

  List<InvoiceData> pendingInvoices() =>
      _invoices.where((i) => !i.isPaid).toList();

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> addInvoice(InvoiceData invoice) =>
      FirebaseService.addInvoice(_toFirestore(invoice));

  Future<void> updateInvoice(String invoiceNo, InvoiceData updated) =>
      FirebaseService.updateInvoice(invoiceNo, _toFirestore(updated));

  Future<void> markAsPaid(String invoiceNo, {double? amount}) {
    final inv = _invoices.firstWhere((i) => i.invoiceNo == invoiceNo,
        orElse: () => throw Exception('Invoice not found'));
    return FirebaseService.markInvoicePaid(
        invoiceNo, amount ?? inv.grandTotal);
  }

  Future<void> deleteInvoice(String invoiceNo) =>
      FirebaseService.deleteInvoice(invoiceNo);

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
