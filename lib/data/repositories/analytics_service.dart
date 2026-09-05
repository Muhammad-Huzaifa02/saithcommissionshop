import 'package:flutter/material.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class AnalyticsService {
  /// Total sales for today
  static double dailyTotal(List<InvoiceData> invoices) {
    final today = DateUtils.dateOnly(DateTime.now());
    return invoices
        .where((i) => DateUtils.isSameDay(i.dateTime, today))
        .fold(0.0, (s, i) => s + InvoiceCalculationService.calculate(i).grandTotal);
  }

  /// Total pending across all invoices
  static double totalPending(List<InvoiceData> invoices) =>
      invoices.fold(0.0, (s, i) => s + InvoiceCalculationService.calculate(i).pendingAmount);

  /// Monthly total for a given month/year
  static double monthlyTotal(List<InvoiceData> invoices, int month, int year) =>
      invoices
          .where((i) => i.dateTime.month == month && i.dateTime.year == year)
          .fold(0.0, (s, i) => s + InvoiceCalculationService.calculate(i).grandTotal);

  /// Sales grouped by month (1–12) for the given year
  static Map<int, double> monthlySalesMap(List<InvoiceData> invoices, int year) {
    final map = <int, double>{};
    for (int m = 1; m <= 12; m++) {
      map[m] = monthlyTotal(invoices, m, year);
    }
    return map;
  }

  /// Top N customers by total spend
  static List<MapEntry<String, double>> topCustomers(
      List<InvoiceData> invoices, int n) {
    final totals = <String, double>{};
    for (var inv in invoices) {
      totals[inv.customerName] =
          (totals[inv.customerName] ?? 0) + InvoiceCalculationService.calculate(inv).grandTotal;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }
}