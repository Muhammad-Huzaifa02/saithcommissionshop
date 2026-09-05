import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';

// NOTE: Stock history is persisted to the Firestore `stock_history`
// collection (see saveInvoiceTransaction / provider.addStock /
// provider.deductStock). This service previously also kept a static
// in-memory `_history` list, but nothing in the app ever read it — it
// reset on every app restart and never matched the real Firestore
// history, so it was removed rather than left as a misleading duplicate.

class StockService {
  /// Add stock bags to a product.
  static void addStock({
    required ProductProvider provider,
    required String productId,
    required int bagCount,
    required String addedBy,
    String? notes,
  }) {
    final kgToAdd = bagCount * 40.0;

    provider.addStock(
      productId: productId,
      addedKg: kgToAdd,
      reference: 'STOCK-IN-${DateTime.now().millisecondsSinceEpoch}',
      adminId: addedBy,
      notes: notes,
    );
  }

  /// Deduct stock (manual adjustment).
  static bool deductStock({
    required ProductProvider provider,
    required String productId,
    required int bagCount,
    required String deductedBy,
    String? notes,
  }) {
    final product = provider.products.firstWhere((p) => p.id == productId);
    final kgToDeduct = bagCount * 40.0;

    if (product.availableStockKg < kgToDeduct) {
      return false;
    }

    provider.deductStock(
      productId: productId,
      usedKg: kgToDeduct,
      invoiceNo: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
      adminId: deductedBy,
    );

    return true;
  }

  static Map<String, int> getLowStockProducts(
      List<Product> products, int thresholdBags) {
    final low = <String, int>{};
    for (final p in products) {
      final bags = (p.availableStockKg / 40).floor();
      if (bags <= thresholdBags) low[p.name] = bags;
    }
    return low;
  }
}
