import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/theme_provider.dart';
import 'package:saithcommissionshop/modules/home/providers/shop_provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/data/models/admin_user_model.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminUserProvider>().currentUser;
    final role  = admin?.role ?? AdminRole.staff;
    final isSuper = role == AdminRole.superAdmin;

    return DefaultTabController(
      length: isSuper ? 4 : 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Advanced Settings'),
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              const Tab(text: 'General', icon: Icon(Icons.tune, size: 20)),
              const Tab(text: 'Account', icon: Icon(Icons.person_outline, size: 20)),
              if (isSuper) ...[
                const Tab(text: 'Shop',   icon: Icon(Icons.storefront, size: 20)),
                const Tab(text: 'System', icon: Icon(Icons.settings_suggest, size: 20)),
              ],
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _GeneralTab(),
            const _AccountTab(),
            if (isSuper) ...[
              const _ShopProfileTab(),
              const _SystemTab(),
            ],
          ],
        ),
      ),
    );
  }
}

// ── General Tab (Appearance & Basics) ──────────────────────────────────────
class _GeneralTab extends StatelessWidget {
  const _GeneralTab();
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(context, 'Display Preferences', [
          _SettingsTile(
            icon: theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            iconColor: AppTheme.green,
            title: 'Dark Mode',
            trailing: Switch(
              value: theme.isDarkMode,
              onChanged: (_) => theme.toggleTheme(),
              activeColor: AppTheme.green,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _section(context, 'App Information', [
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: 'App Version',
            value: AppConstants.appVersion,
          ),
        ]),
      ],
    );
  }
}

// ── Account Tab (Security & Staff) ──────────────────────────────────────────
class _AccountTab extends StatefulWidget {
  const _AccountTab();
  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  final _oldPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();

  @override
  void dispose() { _oldPassCtrl.dispose(); _newPassCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminUserProvider>();
    final admin         = adminProvider.currentUser;
    final isSuperAdmin  = admin?.role == AdminRole.superAdmin;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(context, 'My Identity', [
          _SettingsTile(
            icon: Icons.person_outline,
            iconColor: SColors.catBlue,
            title: 'Full Name',
            value: admin?.name ?? '—',
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.email_outlined,
            iconColor: SColors.catIndigo,
            title: 'Email',
            value: admin?.email ?? '—',
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.badge_outlined,
            iconColor: SColors.catPurple,
            title: 'Role',
            value: admin?.roleDisplayName ?? '—',
          ),
        ]),
        const SizedBox(height: 16),
        
        _section(context, 'Security', [
          _SettingsTile(
            icon: Icons.lock_open,
            iconColor: SColors.warning,
            title: 'Change Password',
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: () => _showPasswordDialog(context),
          ),
        ]),
        const SizedBox(height: 16),

        if (isSuperAdmin) ...[
          _section(context, 'Staff Management', [
            StreamBuilder<List<AdminUser>>(
              stream: adminProvider.staffStream,
              builder: (context, snapshot) {
                final staff = snapshot.data ?? [];
                return Column(
                  children: [
                    ...staff.map((s) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.green.withValues(alpha: 0.1),
                        child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                            style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(s.roleDisplayName, style: const TextStyle(fontSize: 12)),
                      trailing: s.id != admin?.id 
                        ? IconButton(icon: Icon(Icons.delete_outline, color: SColors.error, size: 20), onPressed: () => _confirmRemoveStaff(context, s))
                        : const Chip(label: Text('You', style: TextStyle(fontSize: 10)), padding: EdgeInsets.zero),
                    )),
                  ],
                );
              }
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add_alt, color: AppTheme.green),
              title: const Text('Add Staff Member', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold)),
              onTap: () => _showAddStaffDialog(context),
            ),
          ]),
          const SizedBox(height: 16),
        ],

        OutlinedButton.icon(
          onPressed: () {
            context.read<AdminUserProvider>().logout();
            Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (_) => false);
          },
          icon: const Icon(Icons.logout, color: SColors.error),
          label: const Text('Log Out Securely', style: TextStyle(color: SColors.error, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), side: const BorderSide(color: SColors.error)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Old Password')),
            const SizedBox(height: 12),
            TextField(controller: _newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final ok = await context.read<AdminUserProvider>().changePassword(oldPassword: _oldPassCtrl.text, newPassword: _newPassCtrl.text);
            if (!context.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Success' : 'Failed'), backgroundColor: ok ? SColors.success : SColors.error));
          }, child: const Text('Update')),
        ],
      ),
    );
  }

  void _confirmRemoveStaff(BuildContext context, AdminUser staff) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Staff?'),
        content: Text('This will revoke access for ${staff.name}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SColors.error),
            onPressed: () {
              context.read<AdminUserProvider>().removeStaff(staff.id);
              Navigator.pop(context);
            }, 
            child: const Text('Remove')),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    AdminRole role = AdminRole.staff;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Staff'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdminRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Assigned Role'),
                items: const [
                  DropdownMenuItem(value: AdminRole.manager, child: Text('Manager (Edit access)')),
                  DropdownMenuItem(value: AdminRole.staff,   child: Text('Staff (View only)')),
                ],
                onChanged: (r) => setDialogState(() => role = r!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              final ok = await context.read<AdminUserProvider>().addStaff(name: nameCtrl.text, email: emailCtrl.text, password: passCtrl.text, role: role);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Staff Added' : 'Error adding staff'), backgroundColor: ok ? SColors.success : SColors.error));
            }, child: const Text('Add Member')),
          ],
        ),
      ),
    );
  }
}

// ── Shop Profile Tab (Business Identity) ───────────────────────────────────
class _ShopProfileTab extends StatefulWidget {
  const _ShopProfileTab();
  @override
  State<_ShopProfileTab> createState() => _ShopProfileTabState();
}

class _ShopProfileTabState extends State<_ShopProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _email, _addr, _city, _ntn, _strn;

  @override
  void initState() {
    super.initState();
    final s = context.read<ShopProvider>().shop;
    _name = TextEditingController(text: s.name);
    _phone = TextEditingController(text: s.phone);
    _email = TextEditingController(text: s.email);
    _addr = TextEditingController(text: s.address);
    _city = TextEditingController(text: s.city);
    _ntn = TextEditingController(text: s.ntn);
    _strn = TextEditingController(text: s.strn);
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); _addr.dispose(); _city.dispose(); _ntn.dispose(); _strn.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'Business Identity', [
            _buildField(_name,  'Shop Name *', Icons.store, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            _buildField(_phone, 'Official Phone', Icons.phone, keyboard: TextInputType.phone),
            const SizedBox(height: 12),
            _buildField(_email, 'Official Email', Icons.email, keyboard: TextInputType.emailAddress),
          ]),
          const SizedBox(height: 16),
          _section(context, 'Location Details', [
            _buildField(_addr, 'Address', Icons.location_on, maxLines: 2),
            const SizedBox(height: 12),
            _buildField(_city, 'City', Icons.location_city),
          ]),
          const SizedBox(height: 16),
          _section(context, 'Legal & Tax Info', [
            _buildField(_ntn, 'NTN (National Tax No.)', Icons.receipt_long),
            const SizedBox(height: 12),
            _buildField(_strn, 'STRN (Sales Tax No.)', Icons.assignment),
          ]),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<ShopProvider>().updateShopField(
                  name: _name.text, phone: _phone.text, email: _email.text,
                  address: _addr.text, city: _city.text, ntn: _ntn.text, strn: _strn.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shop details updated'), backgroundColor: SColors.success));
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Business Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── System Tab (Infrastructure) ───────────────────────────────────────────
class _SystemTab extends StatelessWidget {
  const _SystemTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(context, 'Data Management', [
          _SettingsTile(
            icon: Icons.file_download_outlined,
            iconColor: Colors.teal,
            title: 'Full Data Export',
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: () => Navigator.pushNamed(context, '/export'),
          ),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Text(title,
                  style: SText.bodyMd.copyWith(
                      color: isDark ? SColors.darkTextPrimary : SColors.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            if (value != null)
              Flexible(
                flex: 3,
                child: Text(value!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: SText.bodyMd.copyWith(
                        color: isDark ? SColors.darkTextSecondary : SColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

Widget _section(BuildContext context, String title, List<Widget> children) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? SColors.primaryXLight : AppTheme.green,
                letterSpacing: 0.5)),
      ),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: SRadius.radiusLg,
            side: BorderSide(
                color: isDark ? SColors.darkBorder : SColors.border,
                width: 0.5)),
        child: Column(children: children),
      ),
    ],
  );
}

Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text, int maxLines = 1, String? Function(String?)? validator}) =>
  Padding(
    padding: const EdgeInsets.all(12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: SRadius.radiusMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    ),
  );

