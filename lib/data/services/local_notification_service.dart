import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Initialize ─────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS:     iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    await _createChannels();
    _initialized = true;
  }

  static Future<void> _createChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'stock_alerts',
        'Stock Alerts',
        description: 'Low and out-of-stock product alerts',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'payment_reminders',
        'Payment Reminders',
        description: 'Pending payment reminders',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'new_orders',
        'New Orders',
        description: 'New customer order alerts',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'general',
        'General',
        description: 'General app notifications',
        importance: Importance.low,
      ),
    );
  }

  static void _onTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ── Request Permission ─────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ── Stock Alert ────────────────────────────────────────────────────────────
  static Future<void> showStockAlert({
    required String productName,
    required double stockKg,
    required bool   isOutOfStock,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      productName.hashCode,
      isOutOfStock
          ? '🚨 Out of Stock: $productName'
          : '⚠️ Low Stock: $productName',
      isOutOfStock
          ? '$productName is completely out of stock. Restock immediately.'
          : 'Only ${stockKg.toStringAsFixed(0)} kg remaining. Reorder soon.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'stock_alerts',
          'Stock Alerts',
          channelDescription: 'Low and out-of-stock alerts',
          importance: isOutOfStock ? Importance.max   : Importance.high,
          priority:   isOutOfStock ? Priority.max     : Priority.high,
          color:      isOutOfStock
              ? const Color(0xFFD32F2F)
              : const Color(0xFFF57C00),
          styleInformation: BigTextStyleInformation(
            isOutOfStock
                ? '$productName is completely out of stock. Please restock immediately.'
                : 'Only ${stockKg.toStringAsFixed(0)} kg remaining for $productName.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'STOCK',
        ),
      ),
      payload: 'stock:$productName',
    );
  }

  // ── Payment Reminder ───────────────────────────────────────────────────────
  static Future<void> showPaymentReminder({
    required String customerName,
    required double amount,
    required String invoiceNo,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      invoiceNo.hashCode,
      '💰 Payment Pending: $customerName',
      'PKR ${amount.toStringAsFixed(0)} outstanding — Invoice $invoiceNo',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Payment Reminders',
          channelDescription: 'Pending payment reminders',
          importance: Importance.defaultImportance,
          priority:   Priority.defaultPriority,
          color:      const Color(0xFF1976D2),
          styleInformation: BigTextStyleInformation(
            'Customer $customerName has an outstanding balance of '
                'PKR ${amount.toStringAsFixed(0)} on invoice $invoiceNo.',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'PAYMENT',
        ),
      ),
      payload: 'payment:$invoiceNo',
    );
  }

  // ── New Order ──────────────────────────────────────────────────────────────
  static Future<void> showNewOrder({
    required String invoiceNo,
    required String customerName,
    required double total,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      invoiceNo.hashCode,
      '🛍 New Order — $customerName',
      'Invoice $invoiceNo  •  PKR ${total.toStringAsFixed(0)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'new_orders',
          'New Orders',
          channelDescription: 'New customer order alerts',
          importance: Importance.high,
          priority:   Priority.high,
          color:      const Color(0xFF2E7D32),
          ticker:     'New order from $customerName',
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'ORDER',
        ),
      ),
      payload: 'order:$invoiceNo',
    );
  }

  // ── Daily Summary ──────────────────────────────────────────────────────────
  static Future<void> showDailySummary({
    required int    totalOrders,
    required double totalSales,
    required int    pendingCount,
  }) async {
    if (!_initialized) await init();

    await _plugin.show(
      99999,
      '📊 Daily Summary — Saith Commission Shop',
      '$totalOrders orders  •  PKR ${totalSales.toStringAsFixed(0)}  •  $pendingCount pending',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General',
          channelDescription: 'General app notifications',
          importance: Importance.low,
          priority:   Priority.low,
          color:      Color(0xFF2E7D32),
        ),
      ),
      payload: 'summary',
    );
  }

  // ── Bulk Stock Check ───────────────────────────────────────────────────────
  static Future<void> checkAndNotifyStock(List<dynamic> products) async {
    for (final p in products) {
      if (p.isOutOfStock) {
        await showStockAlert(
          productName:  p.name,
          stockKg:      0,
          isOutOfStock: true,
        );
      } else if (p.isLowStock) {
        await showStockAlert(
          productName:  p.name,
          stockKg:      p.availableStockKg as double,
          isOutOfStock: false,
        );
      }
    }
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────
  static Future<void> cancelAll()    async => _plugin.cancelAll();
  static Future<void> cancel(int id) async => _plugin.cancel(id);
}