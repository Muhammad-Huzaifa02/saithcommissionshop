import 'package:saithcommissionshop/data/models/inventory_alert.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';

class InventoryAlertService {
  static const double _lowStockThresholdKg = 200;
  static const double _criticalThresholdKg = 80;
  static const double _outOfStockThresholdKg = 0;

  static List<InventoryAlert> generateAlerts(List<Product> products) {
    final alerts = <InventoryAlert>[];

    for (final product in products) {
      if (product.availableStockKg <= _outOfStockThresholdKg) {
        alerts.add(InventoryAlert(
          id: '${product.id}_out',
          productId: product.id,
          productName: product.name,
          type: AlertType.outOfStock,
          severity: AlertSeverity.critical,
          message:
          '${product.name} is out of stock - order immediately',
          createdAt: DateTime.now(),
          currentStock: product.availableStockKg,
        ));
      } else if (product.availableStockKg <= _criticalThresholdKg) {
        alerts.add(InventoryAlert(
          id: '${product.id}_critical',
          productId: product.id,
          productName: product.name,
          type: AlertType.reorderPoint,
          severity: AlertSeverity.critical,
          message:
          '${product.name} stock is very low (${product.availableStockKg.toStringAsFixed(0)} kg)',
          createdAt: DateTime.now(),
          currentStock: product.availableStockKg,
        ));
      } else if (product.availableStockKg <= _lowStockThresholdKg) {
        alerts.add(InventoryAlert(
          id: '${product.id}_low',
          productId: product.id,
          productName: product.name,
          type: AlertType.lowStock,
          severity: AlertSeverity.medium,
          message:
          '${product.name} stock is running low (${product.availableStockKg.toStringAsFixed(0)} kg)',
          createdAt: DateTime.now(),
          currentStock: product.availableStockKg,
        ));
      }
    }

    alerts.sort((a, b) => a.severity.index.compareTo(b.severity.index));
    return alerts;
  }

  static int criticalCount(List<Product> products) =>
      products.where((p) => p.availableStockKg <= _criticalThresholdKg).length;

  static bool hasAlerts(List<Product> products) =>
      products.any((p) => p.availableStockKg <= _lowStockThresholdKg);
}
