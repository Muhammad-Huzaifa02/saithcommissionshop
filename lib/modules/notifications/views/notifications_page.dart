import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/data/models/notification_model.dart';
import 'package:saithcommissionshop/data/services/stock_alert_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<AppNotification> _notifications = [];
  bool _loaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh timestamps every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) { _loaded = true; _loadNotifications(); }
  }

  void _loadNotifications() {
    final products = context.read<ProductProvider>().products;
    final invoices = context.read<InvoiceProvider>().invoices;

    // Stock alerts
    _notifications.addAll(StockAlertService.checkStockAlerts(products));

    // Pending payment reminders
    for (final inv in invoices.where((i) => !i.isPaid).take(5)) {
      _notifications.add(AppNotification(
        id:       'pay_${inv.invoiceNo}',
        title:    'Payment Reminder',
        titleUr:  'Payment Reminder',
        body:     'Invoice ${inv.invoiceNo} for ${inv.customerName} is pending — PKR ${inv.grandTotal.toStringAsFixed(0)}',
        bodyUr:   'Invoice ${inv.invoiceNo} for ${inv.customerName} is pending — PKR ${inv.grandTotal.toStringAsFixed(0)}',
        type:     NotificationType.paymentReminder,
        priority: NotificationPriority.medium,
        dateTime: inv.dateTime,
        isRead:   false,
      ));
    }

    // New order notifications
    for (final inv in invoices.take(3)) {
      _notifications.add(AppNotification(
        id:       'order_${inv.invoiceNo}',
        title:    'New Order',
        titleUr:  'New Order',
        body:     'Order ${inv.invoiceNo} placed by ${inv.customerName} — PKR ${inv.grandTotal.toStringAsFixed(0)}',
        bodyUr:   'Order ${inv.invoiceNo} placed by ${inv.customerName} — PKR ${inv.grandTotal.toStringAsFixed(0)}',
        type:     NotificationType.orderUpdate,
        priority: NotificationPriority.low,
        dateTime: inv.dateTime,
        isRead:   true,
      ));
    }

    // Sort: high priority first, then newest
    _notifications.sort((a, b) {
      final pd = b.priority.index.compareTo(a.priority.index);
      return pd != 0 ? pd : b.dateTime.compareTo(a.dateTime);
    });

    setState(() {});
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: _unreadCount > 0
          ? 'Notifications ($_unreadCount)'
          : 'Notifications',
      scrollable: false, // Fix unbounded height: ListView inside a scrollable scaffold
      actions: [
        if (_unreadCount > 0)
          TextButton(
            onPressed: () => setState(() {
              for (final n in _notifications) n.isRead = true;
            }),
            child: const Text('Mark all read',
                style: TextStyle(color: Colors.white)),
          ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'clear') setState(() => _notifications.clear());
            if (v == 'refresh') {
              _notifications.clear();
              _loadNotifications();
            }
          },
          icon: const Icon(Icons.more_vert, color: Colors.white),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'refresh', child: Row(children: [Icon(Icons.refresh, size: 18), SizedBox(width: 8), Text('Refresh')])),
            PopupMenuItem(value: 'clear',   child: Row(children: [Icon(Icons.delete_sweep, size: 18, color: SColors.error), SizedBox(width: 8), Text('Clear all', style: TextStyle(color: SColors.error))])),
          ],
        ),
      ],
      body: _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: SColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_none,
                  size: 52, color: SColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            const Text('No notifications',
                style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('You\'re all caught up!',
                style: TextStyle(color: SColors.textSecondary, fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _notifications.length,
        itemBuilder: (_, i) {
          final n = _notifications[i];
          return Dismissible(
            key: Key(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                color: SColors.error,
                borderRadius: SRadius.radiusMd,
              ),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white),
            ),
            onDismissed: (_) =>
                setState(() => _notifications.removeAt(i)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: n.isRead
                    ? Colors.white
                    : n.priorityColor.withValues(alpha: 0.04),
                borderRadius: SRadius.radiusLg,
                border: n.isRead
                    ? Border.all(color: SColors.surfaceAlt)
                    : Border.all(
                    color: n.priorityColor.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                onTap: () =>
                    setState(() => n.isRead = true),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: n.priorityColor.withValues(alpha: 0.1),
                    borderRadius: SRadius.radiusMd,
                  ),
                  child: Icon(n.typeIcon,
                      color: n.priorityColor, size: 24),
                ),
                title: Row(children: [
                  Expanded(
                    child: ResponsiveText(n.title,
                        style: TextStyle(
                            color: n.isRead ? Colors.black87 : SColors.primaryLight,
                            fontWeight: n.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 15)),
                  ),
                  if (!n.isRead)
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: n.priorityColor,
                          shape: BoxShape.circle),
                    ),
                ]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(n.body,
                        style: TextStyle(fontSize: 13, color: SColors.textPrimary, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: SColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(_fmtTime(n.dateTime),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: SColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
    if (diff.inDays < 1)     return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
