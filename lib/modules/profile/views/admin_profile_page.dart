import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminUserProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    (admin?.name ?? 'A').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                Text(admin?.name ?? 'Admin',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(admin?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: SRadius.radiusLg,
                  ),
                  child: Text(
                    (admin?.role.name ?? 'ADMIN').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1),
                  ),
                ),
              ]),
            ),

            // Info Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _InfoCard('Account Details', [
                  _InfoRow(Icons.badge_outlined, 'Admin ID', admin?.id ?? 'N/A'),
                  _InfoRow(Icons.work_outline, 'Role', admin?.roleDisplayName ?? 'N/A'),
                  _InfoRow(Icons.email_outlined, 'Email', admin?.email ?? 'N/A'),
                ]),
                const SizedBox(height: 12),
                _InfoCard('Permissions', [
                  _InfoRow(Icons.inventory_2_outlined, 'Manage Products', 'Full Access'),
                  _InfoRow(Icons.people_outline, 'Manage Customers', 'Full Access'),
                  _InfoRow(Icons.receipt_long_outlined, 'Manage Invoices', 'Full Access'),
                  _InfoRow(Icons.analytics_outlined, 'View Analytics', 'Full Access'),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AdminUserProvider>().logout();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/role-selection', (_) => false);
                    },
                    icon: const Icon(Icons.logout, color: SColors.error),
                    label: const Text('Sign Out',
                        style: TextStyle(color: SColors.error, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: SColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: SRadius.radiusMd),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;
  const _InfoCard(this.title, this.rows);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
                letterSpacing: 0.5)),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: SRadius.radiusMd,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          children: rows.asMap().entries.map((e) => Column(children: [
            e.value,
            if (e.key < rows.length - 1) Divider(height: 1, indent: 56, color: SColors.divider),
          ])).toList(),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppTheme.green.withValues(alpha: 0.08),
        borderRadius: SRadius.radiusMd,
      ),
      child: Icon(icon, color: AppTheme.green, size: 18),
    ),
    title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
  );
}

