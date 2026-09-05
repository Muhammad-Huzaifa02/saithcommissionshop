/// A named set of permission strings, scoped to one shop.
///
/// Five default roles are seeded for every new shop (see
/// [Role.defaultRolesFor]) but owners can edit their permissions or add
/// custom roles — this is what replaces the old fixed `AdminRole` enum.
class Role {
  final String id;
  final String shopId;
  final String name;
  final bool isDefault;
  final List<String> permissions;

  const Role({
    required this.id,
    required this.shopId,
    required this.name,
    this.isDefault = false,
    this.permissions = const [],
  });

  bool has(String permission) => permissions.contains(permission);

  factory Role.fromMap(String id, Map<String, dynamic> d) => Role(
        id: id,
        shopId: d['shopId'] as String? ?? '',
        name: d['name'] as String? ?? '',
        isDefault: d['isDefault'] as bool? ?? false,
        permissions: (d['permissions'] as List?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'isDefault': isDefault,
        'permissions': permissions,
      };

  Role copyWith({String? name, List<String>? permissions}) => Role(
        id: id,
        shopId: shopId,
        name: name ?? this.name,
        isDefault: isDefault,
        permissions: permissions ?? this.permissions,
      );

  /// All permission strings recognized by the app. Kept in one place so
  /// screens and the role editor stay in sync with what's actually checked.
  static const List<String> allPermissions = [
    'view_dashboard',
    'manage_products',
    'manage_inventory',
    'manage_customers',
    'manage_suppliers',
    'create_sale',
    'create_purchase',
    'create_invoice',
    'edit_invoice',
    'delete_invoice',
    'void_invoice',
    'create_receipt',
    'manage_expenses',
    'view_ledger',
    'view_analytics',
    'view_reports',
    'export_data',
    'manage_employees',
    'manage_roles',
    'manage_settings',
    'send_reminders',
  ];

  /// Seed data for a brand-new shop's five default roles. Callers pass the
  /// real shopId once the shop document has been created.
  static List<Role> defaultRolesFor(String shopId) => [
        Role(
          id: 'owner',
          shopId: shopId,
          name: 'Owner',
          isDefault: true,
          permissions: allPermissions,
        ),
        Role(
          id: 'manager',
          shopId: shopId,
          name: 'Manager',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_products', 'manage_inventory',
            'manage_customers', 'manage_suppliers', 'create_sale',
            'create_purchase', 'create_invoice', 'edit_invoice',
            'view_ledger', 'view_analytics', 'view_reports', 'export_data',
            'send_reminders',
          ],
        ),
        Role(
          id: 'accountant',
          shopId: shopId,
          name: 'Accountant',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_customers', 'manage_suppliers',
            'create_invoice', 'create_receipt', 'manage_expenses',
            'view_ledger', 'view_reports', 'export_data',
          ],
        ),
        Role(
          id: 'sales_staff',
          shopId: shopId,
          name: 'Sales Staff',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_customers', 'create_sale',
            'create_invoice',
          ],
        ),
        Role(
          id: 'inventory_staff',
          shopId: shopId,
          name: 'Inventory Staff',
          isDefault: true,
          permissions: const [
            'view_dashboard', 'manage_products', 'manage_inventory',
          ],
        ),
      ];

  /// Shape expected by FirebaseService.createShopWithOwner's `defaultRoles`
  /// param — each map keeps 'id' alongside the Firestore field map so the
  /// batch write can use it as the doc id and then drop it from the data.
  static List<Map<String, dynamic>> defaultRoleSeedMaps(String shopId) =>
      defaultRolesFor(shopId).map((r) => {'id': r.id, ...r.toMap()}).toList();
}
