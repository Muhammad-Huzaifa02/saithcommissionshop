import 'package:flutter/material.dart';

enum NotificationType { stockAlert, paymentReminder, orderUpdate, general }
enum NotificationPriority { low, medium, high, critical }

class AppNotification {
  final String             id;
  final String             title;
  final String             titleUr;
  final String             body;
  final String             bodyUr;
  final NotificationType   type;
  final NotificationPriority priority;
  final DateTime           dateTime;
  bool                     isRead;
  final Map<String, String> data;

  AppNotification({
    required this.id,
    required this.title,
    String?  titleUr,
    required this.body,
    String?  bodyUr,
    required this.type,
    required this.priority,
    required this.dateTime,
    this.isRead = false,
    this.data   = const {},
  })  : titleUr = titleUr ?? title,
        bodyUr  = bodyUr  ?? body;

  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.critical: return const Color(0xFFD32F2F);
      case NotificationPriority.high:     return const Color(0xFFF57C00);
      case NotificationPriority.medium:   return const Color(0xFF1976D2);
      case NotificationPriority.low:      return const Color(0xFF388E3C);
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.stockAlert:      return Icons.inventory_2_outlined;
      case NotificationType.paymentReminder: return Icons.payment_outlined;
      case NotificationType.orderUpdate:     return Icons.shopping_bag_outlined;
      case NotificationType.general:         return Icons.notifications_outlined;
    }
  }
}