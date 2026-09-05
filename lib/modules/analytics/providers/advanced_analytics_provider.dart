import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/advanced_analytics.dart';

class AdvancedAnalyticsProvider extends ChangeNotifier {
  List<SalesForecasting>      _forecasts          = [];
  List<ProductPerformance>    _productPerformance = [];
  List<CustomerLifetimeValue> _customerLTV        = [];
  List<ProfitMarginAnalysis>  _profitMargins      = [];
  double                      _growthRate         = 0;

  List<SalesForecasting>      get forecasts          => _forecasts;
  List<ProductPerformance>    get productPerformance  => _productPerformance;
  List<CustomerLifetimeValue> get customerLTV         => _customerLTV;
  List<ProfitMarginAnalysis>  get profitMargins       => _profitMargins;
  double                      get growthRate          => _growthRate;

  void updateForecasts(List<SalesForecasting> f) {
    _forecasts = f; notifyListeners();
  }
  void updateProductPerformance(List<ProductPerformance> p) {
    _productPerformance = p; notifyListeners();
  }
  void updateCustomerLTV(List<CustomerLifetimeValue> l) {
    _customerLTV = l; notifyListeners();
  }
  void updateProfitMargins(List<ProfitMarginAnalysis> m) {
    _profitMargins = m; notifyListeners();
  }
  void updateGrowthRate(double r) {
    _growthRate = r; notifyListeners();
  }
}
