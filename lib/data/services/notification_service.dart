import 'package:saithcommissionshop/data/models/notification_model.dart';

class NotificationService {
  static final List<AppNotification> _notifications = [];

  static List<AppNotification> get all => List.unmodifiable(_notifications);
  static List<AppNotification> get unread =>
      _notifications.where((n) => !n.isRead).toList();
  static int get unreadCount => unread.length;

  static void add(AppNotification notification) {
    _notifications.insert(0, notification);
  }

  static void addLowStock(String productName, double stockKg) {
    add(AppNotification(
      id: 'stock_${productName}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Low Stock Alert',
      body: '$productName is running low (${stockKg.toStringAsFixed(0)} kg remaining)',
      type: NotificationType.stockAlert,
      priority: NotificationPriority.high,
      dateTime: DateTime.now(),
      isRead: false,
    ));
  }

  static void addPaymentReceived(String customerName, double amount) {
    add(AppNotification(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Received',
      body: 'Received PKR ${amount.toStringAsFixed(0)} from $customerName',
      type: NotificationType.paymentReminder,
      priority: NotificationPriority.medium,
      dateTime: DateTime.now(),
      isRead: false,
    ));
  }

  static void addNewOrder(String customerName, String invoiceNo) {
    add(AppNotification(
      id: 'order_$invoiceNo',
      title: 'New Order',
      body: 'New order $invoiceNo from $customerName',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.medium,
      dateTime: DateTime.now(),
      isRead: false,
    ));
  }

  static void addPendingPayment(String customerName, double pendingAmount) {
    add(AppNotification(
      id: 'pending_${customerName}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Pending Payment',
      body: 'PKR ${pendingAmount.toStringAsFixed(0)} pending from $customerName',
      type: NotificationType.paymentReminder,
      priority: NotificationPriority.medium,
      dateTime: DateTime.now(),
      isRead: false,
    ));
  }

  static void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) _notifications[idx].isRead = true;
  }

  static void markAllRead() {
    for (final n in _notifications) { n.isRead = true; }
  }

  static void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  static void clear() => _notifications.clear();
}
