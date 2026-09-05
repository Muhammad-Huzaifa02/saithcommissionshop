import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/data/models/customer_model.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().currentCustomer;
    final ip       = context.watch<InvoiceProvider>();

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final invoices   = ip.invoicesByCustomer(customer.id);
    final totalSpent = invoices.fold(0.0, (s, inv) =>
    s + inv.products.fold(0.0, (ps, p) => ps + p.quantity * p.pricePer40kg));
    final pending    = ip.customerBalance(customer.id);

    // Tier logic
    String tier, tierLabel;
    Color tierColor;
    IconData tierIcon;
    double nextThreshold;
    if (totalSpent >= 500000) {
      tier = 'Platinum'; tierLabel = 'Platinum';
      tierColor = SColors.catPurple; tierIcon = Icons.diamond;
      nextThreshold = 500000;
    } else if (totalSpent >= 100000) {
      tier = 'Gold'; tierLabel = 'Gold';
      tierColor = Colors.amber.shade700; tierIcon = Icons.emoji_events;
      nextThreshold = 500000;
    } else if (totalSpent >= 50000) {
      tier = 'Silver'; tierLabel = 'Silver';
      tierColor = Colors.blueGrey; tierIcon = Icons.military_tech;
      nextThreshold = 100000;
    } else {
      tier = 'Bronze'; tierLabel = 'Bronze';
      tierColor = Colors.brown; tierIcon = Icons.workspace_premium;
      nextThreshold = 50000;
    }
    final tierProgress = (totalSpent / nextThreshold).clamp(0.0, 1.0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 280,
            pinned: true,
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _showEditProfileDialog(context, customer),
                tooltip: 'Edit Profile',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tierColor.withValues(alpha: 0.8), SColors.primaryLight],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: () => _pickProfileImage(context, customer.id),
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: tierColor, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15)],
                            image: customer.imageUrl != null 
                              ? DecorationImage(image: NetworkImage(customer.imageUrl!), fit: BoxFit.cover)
                              : null,
                          ),
                          child: customer.imageUrl == null ? Center(
                            child: Text(
                              customer.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: tierColor),
                            ),
                          ) : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ResponsiveText(customer.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone, color: SColors.textOnDarkSub, size: 14),
                          const SizedBox(width: 4),
                          Flexible(child: Text(customer.phone, style: TextStyle(fontSize: 12, color: SColors.textOnDarkSub), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email, color: SColors.textOnDarkSub, size: 14),
                          const SizedBox(width: 4),
                          Flexible(child: Text(customer.email, style: TextStyle(fontSize: 12, color: SColors.textOnDarkSub), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('ID: ${customer.customerId}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierColor,
                          borderRadius: SRadius.radiusLg,
                          boxShadow: [BoxShadow(color: tierColor.withValues(alpha: 0.4), blurRadius: 10)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tierIcon, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(tierLabel,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats ─────────────────────────────────────────
                  Row(children: [
                    _StatCard(
                      'Total Orders',
                      '${invoices.length}',
                      Icons.shopping_bag_outlined,
                      SColors.catBlue,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      'Total Spent',
                      'PKR ${(totalSpent / 1000).toStringAsFixed(0)}K',
                      Icons.payments_outlined,
                      SColors.success,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      'Pending',
                      'PKR ${(pending / 1000).toStringAsFixed(0)}K',
                      Icons.pending_outlined,
                      SColors.warning,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Loyalty Progress ──────────────────────────────
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: SRadius.radiusLg),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Loyalty Program',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Icon(tierIcon, color: tierColor),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: SRadius.radiusMd,
                            child: LinearProgressIndicator(
                              value: tierProgress,
                              minHeight: 12,
                              backgroundColor: SColors.border,
                              valueColor: AlwaysStoppedAnimation(tierColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PKR ${totalSpent.toStringAsFixed(0)}',
                                style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                tier == 'Platinum'
                                    ? ('Max tier reached!')
                                    : ('PKR ${nextThreshold.toStringAsFixed(0)} for next tier'),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Tier milestones
                          SafeRow(
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              _TierBadge('Bronze', Colors.brown, Icons.workspace_premium, totalSpent >= 0),
                              _TierBadge('Silver', Colors.blueGrey, Icons.military_tech, totalSpent >= 50000),
                              _TierBadge('Gold', Colors.amber.shade700, Icons.emoji_events, totalSpent >= 100000),
                              _TierBadge('Platinum', SColors.catPurple, Icons.diamond, totalSpent >= 500000),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Recent Orders ─────────────────────────────────
                  Text(
                    'Recent Orders',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  if (invoices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No orders yet',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...invoices.take(5).map((inv) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: inv.isPaid
                              ? SColors.success.withValues(alpha: 0.1)
                              : SColors.warning.withValues(alpha: 0.1),
                          child: Icon(
                            inv.isPaid ? Icons.check_circle : Icons.pending,
                            color: inv.isPaid ? SColors.success : SColors.warning,
                          ),
                        ),
                        title: Text(inv.invoiceNo,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          '${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year} · ${inv.customerDisplayId ?? "GUEST"}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IntrinsicWidth(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PKR ${inv.products.fold(0.0, (s, p) => s + p.quantity * p.pricePer40kg).toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: inv.isPaid
                                      ? SColors.success.withValues(alpha: 0.1)
                                      : SColors.warning.withValues(alpha: 0.1),
                                  borderRadius: SRadius.radiusSm,
                                ),
                                child: Text(
                                  inv.isPaid
                                      ? ('Paid')
                                      : ('Pending'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: inv.isPaid ? SColors.success : SColors.warning,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  const SizedBox(height: 20),

                  // ── Actions ───────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/order-history'),
                    icon: const Icon(Icons.history),
                    label: Text('View All Orders'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/customer-ledger', arguments: {
                        'customerId': customer.id,
                        'customerName': customer.name,
                      });
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: Text('View Ledger'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<CustomerProvider>().logout();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/role-selection', (_) => false);
                    },
                    icon: const Icon(Icons.logout),
                    label: Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SColors.error,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(BuildContext context, String customerId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (!context.mounted) return;
    if (picked != null) {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading picture...')));
      await context.read<CustomerProvider>().uploadProfilePicture(customerId, File(picked.path));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: SColors.success));
    }
  }

  void _showEditProfileDialog(BuildContext context, Customer customer) {
    final nameCtrl = TextEditingController(text: customer.name);
    final emailCtrl = TextEditingController(text: customer.email);
    final phoneCtrl = TextEditingController(text: customer.phone);
    final addressCtrl = TextEditingController(text: customer.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updated = customer.copyWith(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                );
                await context.read<CustomerProvider>().updateCustomer(customer.id, updated);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profile updated successfully'), backgroundColor: SColors.success),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class _TierBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool achieved;
  const _TierBadge(this.label, this.color, this.icon, this.achieved);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: achieved ? color.withValues(alpha: 0.15) : SColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(
              color: achieved ? color : SColors.textTertiary, width: 2),
        ),
        child: Icon(icon,
            color: achieved ? color : SColors.textTertiary, size: 20),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 9,
              color: achieved ? color : Colors.grey,
              fontWeight: achieved ? FontWeight.bold : FontWeight.normal)),
    ],
  );
}
