class SalesForecasting {
  final DateTime date;
  final double predictedSales;
  final double confidence;

  SalesForecasting({
    required this.date,
    required this.predictedSales,
    required this.confidence,
  });
}

class ProductPerformance {
  final String productId;
  final String productName;
  final double totalRevenue;
  final int unitsSold;
  final double profitMargin;
  final double growthRate;
  final int rank;

  ProductPerformance({
    required this.productId,
    required this.productName,
    required this.totalRevenue,
    required this.unitsSold,
    required this.profitMargin,
    required this.growthRate,
    required this.rank,
  });
}

class CustomerLifetimeValue {
  final String customerId;
  final String customerName;
  final double totalSpent;
  final int orderCount;
  final double averageOrderValue;
  final double predictedLifetimeValue;
  final String tier;

  CustomerLifetimeValue({
    required this.customerId,
    required this.customerName,
    required this.totalSpent,
    required this.orderCount,
    required this.averageOrderValue,
    required this.predictedLifetimeValue,
    required this.tier,
  });
}

class ProfitMarginAnalysis {
  final String period;
  final double revenue;
  final double costs;
  final double grossProfit;
  final double netProfit;
  final double marginPercentage;

  ProfitMarginAnalysis({
    required this.period,
    required this.revenue,
    required this.costs,
    required this.grossProfit,
    required this.netProfit,
    required this.marginPercentage,
  });
}
