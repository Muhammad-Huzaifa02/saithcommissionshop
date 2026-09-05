import 'package:saithcommissionshop/data/models/customer_extended.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class CustomerManagementService {
  static String _tierFor(double totalSpent) {
    if (totalSpent >= 500000) {
      return 'Platinum';
    }
    if (totalSpent >= 200000) {
      return 'Gold';
    }
    if (totalSpent >= 50000) {
      return 'Silver';
    }
    return 'Bronze';
  }

  static int _pointsFor(double amount) => (amount / 1000).floor();

  static CustomerExtended updateFromInvoices(
      CustomerExtended customer,
      List<InvoiceData> invoices,
      ) {
    final customerInvoices =
    invoices.where((i) => i.customerId == customer.id).toList();

    double totalSpent = 0;
    double totalPending = 0;

    for (var inv in customerInvoices) {
      final calc = InvoiceCalculationService.calculate(inv);
      totalSpent += calc.grandTotal;
      totalPending += calc.pendingAmount;
    }

    return customer.copyWith(
      tier: _tierFor(totalSpent),
      loyaltyPoints: customer.loyaltyPoints + _pointsFor(totalSpent),
      usedCredit: totalPending,
    );
  }

  static List<CustomerExtended> sortByTier(List<CustomerExtended> customers) {
    const tierOrder = {'Platinum': 0, 'Gold': 1, 'Silver': 2, 'Bronze': 3};
    return [...customers]
      ..sort((a, b) =>
          (tierOrder[a.tier] ?? 3).compareTo(tierOrder[b.tier] ?? 3));
  }

  static List<CustomerExtended> getHighRiskCustomers(
      List<CustomerExtended> customers, {
        double threshold = 50000,
      }) =>
      customers.where((c) => c.usedCredit >= threshold).toList();

  static Map<String, int> tierDistribution(
      List<CustomerExtended> customers) => {
    'Platinum': customers.where((c) => c.tier == 'Platinum').length,
    'Gold': customers.where((c) => c.tier == 'Gold').length,
    'Silver': customers.where((c) => c.tier == 'Silver').length,
    'Bronze': customers.where((c) => c.tier == 'Bronze').length,
  };
}
