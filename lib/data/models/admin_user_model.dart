enum AdminRole {
  superAdmin,
  manager,
  staff,
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final AdminRole role;
  final DateTime? lastLogin;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.lastLogin,
  });

  String get roleString => role.toString().split('.').last;

  String get roleDisplayName {
    switch (role) {
      case AdminRole.superAdmin: return 'Super Admin';
      case AdminRole.manager: return 'Manager';
      case AdminRole.staff: return 'Staff';
    }
  }

  bool get canDelete => role == AdminRole.superAdmin;
  bool get canEditProducts => role == AdminRole.superAdmin || role == AdminRole.manager;
  bool get canViewAnalytics => role == AdminRole.superAdmin || role == AdminRole.manager;
  bool get canCreateInvoice => true;
  bool get canViewStock => true;
  bool get canManageCustomers => role == AdminRole.superAdmin || role == AdminRole.manager;
  bool get canExportData => role == AdminRole.superAdmin || role == AdminRole.manager;
}
