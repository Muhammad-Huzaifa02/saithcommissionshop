import 'package:saithcommissionshop/data/models/admin_user_model.dart';

class PermissionService {
  static const Map<AdminRole, List<String>> _permissions = {
    AdminRole.superAdmin: [
      'view_dashboard', 'manage_products', 'create_invoice', 'edit_invoice',
      'delete_invoice', 'void_invoice', 'manage_customers', 'view_analytics',
      'export_data', 'manage_settings', 'manage_users', 'view_ledger',
      'manage_stock', 'send_reminders', 'view_reports',
    ],
    AdminRole.manager: [
      'view_dashboard', 'manage_products', 'create_invoice', 'edit_invoice',
      'manage_customers', 'view_analytics', 'export_data', 'view_ledger',
      'manage_stock', 'send_reminders', 'view_reports',
    ],
    AdminRole.staff: [
      'view_dashboard', 'create_invoice', 'view_analytics', 'manage_stock',
    ],
  };

  static bool hasPermission(AdminRole role, String permission) =>
      (_permissions[role] ?? []).contains(permission);

  static List<String> getPermissions(AdminRole role) =>
      List.unmodifiable(_permissions[role] ?? []);

  static bool canDeleteInvoice(AdminRole role) =>
      hasPermission(role, 'delete_invoice');

  static bool canVoidInvoice(AdminRole role) =>
      hasPermission(role, 'void_invoice');

  static bool canManageUsers(AdminRole role) =>
      hasPermission(role, 'manage_users');

  static bool canExportData(AdminRole role) =>
      hasPermission(role, 'export_data');

  static bool canManageSettings(AdminRole role) =>
      hasPermission(role, 'manage_settings');
}
