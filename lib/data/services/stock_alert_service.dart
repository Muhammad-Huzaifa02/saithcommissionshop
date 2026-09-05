import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/data/models/notification_model.dart';

class StockAlertService {
  /// Checks all products and returns notification alerts for low/out of stock
  static List<AppNotification> checkStockAlerts(List<Product> products) {
    final alerts = <AppNotification>[];
    final now = DateTime.now();

    for (final p in products) {
      if (p.isOutOfStock) {
        alerts.add(AppNotification(
          id: 'stock_out_${p.id}',
          title: 'Out of Stock Alert',
          body: '${p.name} is completely out of stock. Please reorder immediately.',
          type: NotificationType.stockAlert,
          priority: NotificationPriority.high,
          dateTime: now,
          isRead: false,
          data: {'productId': p.id, 'stock': '0'},
        ));
      } else if (p.isLowStock) {
        alerts.add(AppNotification(
          id: 'stock_low_${p.id}',
          title: 'Low Stock Warning',
          body: '${p.name} is running low (${p.availableStockKg.toStringAsFixed(0)} kg remaining).',
          type: NotificationType.stockAlert,
          priority: NotificationPriority.medium,
          dateTime: now,
          isRead: false,
          data: {'productId': p.id, 'stock': p.availableStockKg.toString()},
        ));
      }
    }
    return alerts;
  }

  /// Returns summary stats
  static Map<String, int> getStockSummary(List<Product> products) => {
    'total': products.length,
    'outOfStock': products.where((p) => p.isOutOfStock).length,
    'lowStock': products.where((p) => p.isLowStock && !p.isOutOfStock).length,
    'healthy': products.where((p) => !p.isLowStock).length,
  };
}
