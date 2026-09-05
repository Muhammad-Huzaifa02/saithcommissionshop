import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  final List<Payment> _payments = [];
  List<Payment> get payments => List.unmodifiable(_payments);

  double get totalPaid =>
      _payments.fold(0.0, (sum, p) => sum + p.amount);

  void addPayment(
      double amount, {
        String customerId = '',
        String method = 'cash',
      }) {
    _payments.add(Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: customerId,
      amount: amount,
      dateTime: DateTime.now(),
      method: method,
    ));
    notifyListeners();
  }

  List<Payment> paymentsForCustomer(String customerId) =>
      _payments.where((p) => p.customerId == customerId).toList();

  double customerTotalPaid(String customerId) =>
      paymentsForCustomer(customerId)
          .fold(0.0, (sum, p) => sum + p.amount);
}
