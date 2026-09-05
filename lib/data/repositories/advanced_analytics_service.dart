import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/data/models/advanced_analytics.dart';
import '../services/invoice_calculation_service.dart';

class AdvancedAnalyticsService {
  /// Matches an invoice line item to a catalog product: by productId when
  /// available (stable), falling back to name for older invoices saved
  /// before productId was tracked.
  static Product? _matchProduct(List<Product> products, InvoiceProduct item) {
    if (item.productId != null && item.productId!.isNotEmpty) {
      for (final p in products) {
        if (p.id == item.productId) return p;
      }
    }
    for (final p in products) {
      if (p.name == item.name) return p;
    }
    return null;
  }

  // ── SALES FORECASTING (linear trend over recent daily sales) ──────────────
  // This is a simple heuristic, not a statistical/ML model: it fits a
  // straight line through the recent daily totals and blends it with the
  // recent average to avoid wild extrapolation from a short, noisy window.
  // Confidence decreases the further out a day is and with less historical
  // data available — it does NOT use randomness (a previous version added
  // random noise to the prediction itself, which made the forecast
  // non-deterministic and not meaningfully more accurate).
  static List<SalesForecasting> forecastSales(
      List<InvoiceData> historicalInvoices,
      int daysToForecast,
      ) {
    if (historicalInvoices.isEmpty) return [];

    final dailySales = <DateTime, double>{};
    for (var inv in historicalInvoices) {
      final date = DateTime(inv.dateTime.year, inv.dateTime.month, inv.dateTime.day);
      dailySales[date] = (dailySales[date] ?? 0) +
          InvoiceCalculationService.calculate(inv).grandTotal;
    }

    final sortedDates = dailySales.keys.toList()..sort();
    final windowDates = sortedDates.length > 14
        ? sortedDates.sublist(sortedDates.length - 14)
        : sortedDates;
    final ySeries = windowDates.map((d) => dailySales[d]!).toList();
    final n = ySeries.length;

    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += ySeries[i];
      sumXY += i * ySeries[i];
      sumXX += i * i;
    }
    final denom = (n * sumXX - sumX * sumX);
    final slope = (n > 1 && denom != 0) ? (n * sumXY - sumX * sumY) / denom : 0.0;
    final intercept = n > 0 ? (sumY - slope * sumX) / n : 0.0;
    final average = n > 0 ? sumY / n : 0.0;

    final lastDate = sortedDates.last;
    final forecasts = <SalesForecasting>[];
    for (int i = 1; i <= daysToForecast; i++) {
      final x = n - 1 + i;
      final trendValue = intercept + slope * x;
      final predicted = ((trendValue + average) / 2).clamp(0, double.infinity).toDouble();
      final dataConfidence = (n / 14).clamp(0.0, 1.0);
      final distanceDecay = (1.0 - i * 0.04).clamp(0.0, 1.0);
      forecasts.add(SalesForecasting(
        date: lastDate.add(Duration(days: i)),
        predictedSales: predicted,
        confidence: (dataConfidence * distanceDecay).clamp(0.05, 0.95),
      ));
    }
    return forecasts;
  }

  // ── PRODUCT PERFORMANCE ───────────────────────────────────────────────────
  // Cost is now the real cost of goods (product.lastPurchasePrice), not a
  // flat assumed percentage of revenue. Growth rate compares real revenue
  // in the last 30 days against the 30 days before that, not a random
  // number.
  static List<ProductPerformance> analyzeProductPerformance(
      List<InvoiceData> invoices,
      List<Product> products,
      ) {
    final now = DateTime.now();
    final periodStart = now.subtract(const Duration(days: 30));
    final prevPeriodStart = now.subtract(const Duration(days: 60));

    final stats = <String, Map<String, dynamic>>{};

    for (var inv in invoices) {
      for (var item in inv.products) {
        final p = _matchProduct(products, item);
        final id = p?.id ?? 'unmatched-${item.name}';
        final revenue = item.pricePer40kg * item.quantity;
        final cost = p != null ? (p.lastPurchasePrice / 40) * item.totalWeightKg : 0.0;

        stats.putIfAbsent(id, () => {
          'name': item.name,
          'revenue': 0.0,
          'units': 0,
          'cost': 0.0,
          'currentPeriodRevenue': 0.0,
          'prevPeriodRevenue': 0.0,
        });

        stats[id]!['revenue'] = (stats[id]!['revenue'] as double) + revenue;
        stats[id]!['units'] = (stats[id]!['units'] as int) + item.quantity;
        stats[id]!['cost'] = (stats[id]!['cost'] as double) + cost;

        if (!inv.dateTime.isBefore(periodStart)) {
          stats[id]!['currentPeriodRevenue'] = (stats[id]!['currentPeriodRevenue'] as double) + revenue;
        } else if (!inv.dateTime.isBefore(prevPeriodStart)) {
          stats[id]!['prevPeriodRevenue'] = (stats[id]!['prevPeriodRevenue'] as double) + revenue;
        }
      }
    }

    final performances = stats.entries.map((e) {
      final revenue = e.value['revenue'] as double;
      final cost = e.value['cost'] as double;
      final profit = revenue - cost;
      final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
      final curr = e.value['currentPeriodRevenue'] as double;
      final prev = e.value['prevPeriodRevenue'] as double;
      final growth = prev > 0
          ? ((curr - prev) / prev) * 100
          : (curr > 0 ? 100.0 : 0.0);
      return ProductPerformance(
        productId: e.key,
        productName: e.value['name'] as String,
        totalRevenue: revenue,
        unitsSold: e.value['units'] as int,
        profitMargin: margin,
        growthRate: growth,
        rank: 0,
      );
    }).toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    for (int i = 0; i < performances.length; i++) {
      performances[i] = ProductPerformance(
        productId: performances[i].productId,
        productName: performances[i].productName,
        totalRevenue: performances[i].totalRevenue,
        unitsSold: performances[i].unitsSold,
        profitMargin: performances[i].profitMargin,
        growthRate: performances[i].growthRate,
        rank: i + 1,
      );
    }
    return performances;
  }

  // ── CUSTOMER LTV ──────────────────────────────────────────────────────────
  // predictedLifetimeValue is a simple heuristic (assumes the next 12
  // orders will average the same value as past orders) — a real
  // prediction model is out of scope for this app, so this is clearly
  // labeled as a projection, not a precise figure.
  static List<CustomerLifetimeValue> calculateCustomerLTV(
      List<InvoiceData> invoices) {
    final stats = <String, Map<String, dynamic>>{};
    for (var inv in invoices) {
      stats.putIfAbsent(inv.customerId,
              () => {'name': inv.customerName, 'totalSpent': 0.0, 'orderCount': 0});
      stats[inv.customerId]!['totalSpent'] =
          (stats[inv.customerId]!['totalSpent'] as double) +
              InvoiceCalculationService.calculate(inv).grandTotal;
      stats[inv.customerId]!['orderCount'] =
          (stats[inv.customerId]!['orderCount'] as int) + 1;
    }

    return stats.entries.map((e) {
      final spent = e.value['totalSpent'] as double;
      final count = e.value['orderCount'] as int;
      final avg = count > 0 ? spent / count : 0.0;
      return CustomerLifetimeValue(
        customerId: e.key,
        customerName: e.value['name'] as String,
        totalSpent: spent,
        orderCount: count,
        averageOrderValue: avg,
        predictedLifetimeValue: avg * 12,
        tier: spent > 100000 ? 'Gold' : spent > 50000 ? 'Silver' : 'Bronze',
      );
    }).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
  }

  // ── PROFIT MARGIN ANALYSIS ────────────────────────────────────────────────
  // Costs are now real: cost of goods sold from product.lastPurchasePrice,
  // plus the invoice's actual labor/transport/packing/other charges — not
  // a flat assumed percentage of revenue. Revenue here is product sales
  // only (matching what COGS is computed against); commission is added
  // back as the shop's own earned income, consistent with how the Profit
  // Dashboard page treats it.
  static List<ProfitMarginAnalysis> analyzeProfitMargins(
      List<InvoiceData> invoices, String period, List<Product> products) {
    final grouped = <String, List<InvoiceData>>{};
    for (var inv in invoices) {
      final key = period == 'daily'
          ? '${inv.dateTime.year}-${inv.dateTime.month}-${inv.dateTime.day}'
          : period == 'weekly'
          ? '${inv.dateTime.year}-W${((inv.dateTime.day - 1) ~/ 7) + 1}'
          : '${inv.dateTime.year}-${inv.dateTime.month}';
      grouped.putIfAbsent(key, () => []).add(inv);
    }

    return grouped.entries.map((e) {
      double revenue = 0, cogs = 0, commission = 0, charges = 0;
      for (var inv in e.value) {
        final t = InvoiceCalculationService.calculate(inv);
        revenue += t.productsTotal;
        commission += t.commission;
        charges += inv.laborCharges + inv.transportCharges + inv.packingCharges + inv.otherCharges;

        for (var item in inv.products) {
          final p = _matchProduct(products, item);
          if (p != null) cogs += (p.lastPurchasePrice / 40) * item.totalWeightKg;
        }
      }
      final gross = revenue - cogs + commission;
      final net = gross - charges;
      return ProfitMarginAnalysis(
        period: e.key,
        revenue: revenue,
        costs: cogs + charges,
        grossProfit: gross,
        netProfit: net,
        marginPercentage: revenue > 0 ? (net / revenue) * 100 : 0,
      );
    }).toList();
  }

  // ── INVENTORY TURNOVER ────────────────────────────────────────────────────
  static Map<String, double> calculateInventoryTurnover(
      List<Product> products, List<InvoiceData> invoices) {
    final rates = <String, double>{};
    for (var p in products) {
      double totalSold = 0;
      for (var inv in invoices) {
        for (var item in inv.products) {
          final matched = _matchProduct(products, item);
          if (matched?.id == p.id) totalSold += item.quantity;
        }
      }
      final avgInv = p.availableStockKg / 40;
      rates[p.name] = avgInv > 0 ? totalSold / avgInv : 0.0;
    }
    return rates;
  }

  // ── GROWTH RATE ───────────────────────────────────────────────────────────
  static double calculateGrowthRate(
      List<InvoiceData> current, List<InvoiceData> previous) {
    double sum(List<InvoiceData> list) => list.fold(
        0.0, (s, i) => s + InvoiceCalculationService.calculate(i).grandTotal);
    final prev = sum(previous);
    if (prev == 0) return 0;
    return ((sum(current) - prev) / prev) * 100;
  }
}
