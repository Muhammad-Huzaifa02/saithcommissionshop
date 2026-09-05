import 'package:flutter/material.dart';

enum AlertSeverity { low, medium, high, critical }
enum AlertType { lowStock, outOfStock, expiringStock, reorderPoint }

class InventoryAlert {
  final String id;
  final String productId;
  final String productName;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final double? currentStock;
  final double? reorderPoint;

  InventoryAlert({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.severity,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.currentStock,
    this.reorderPoint,
  });

  Color get severityColor {
    switch (severity) {
      case AlertSeverity.low: return Colors.blue;
      case AlertSeverity.medium: return Colors.orange;
      case AlertSeverity.high: return Colors.red;
      case AlertSeverity.critical: return Colors.red.shade900;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.lowStock: return Icons.warning_amber;
      case AlertType.outOfStock: return Icons.error;
      case AlertType.expiringStock: return Icons.schedule;
      case AlertType.reorderPoint: return Icons.shopping_cart;
    }
  }
}