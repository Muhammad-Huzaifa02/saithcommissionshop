import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/reminders/providers/reminder_provider.dart';
import 'package:saithcommissionshop/modules/reminders/providers/reminder_log_provider.dart';
import 'package:saithcommissionshop/data/models/reminder_log_model.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/data/services/whatsapp_service.dart';
import 'package:saithcommissionshop/modules/orders/views/customer_invoice_pages.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});
  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  String _search = '';
  String _filter = 'all'; // all | active | pending

  @override
  Widget build(BuildContext context) {
    final ip          = context.watch<InvoiceProvider>();
    final cp          = context.watch<CustomerProvider>();
    final summaries   = ip.customerSummaries;

    // Merge registered customers with invoice-based customers
    final allCustomerIds = <String>{};
    final mergedList     = <Map<String, dynamic>>[];

    // First add invoice-based summaries
    for (final s in summaries) {
      final cust = cp.getCustomerById(s['id'] as String);
      allCustomerIds.add(s['id'] as String);
      mergedList.add({
        ...s,
        'displayId': cust?.customerId ?? 'N/A',
      });
    }

    // Add registered customers who haven't ordered yet
    for (final c in cp.customers) {
      if (!allCustomerIds.contains(c.id)) {
        mergedList.add({
          'id':        c.id,
          'displayId': c.customerId,
          'name':      c.name,
          'phone':     c.phone,
          'total':     0.0,
          'paid':      0.0,
          'pending':   0.0,
          'count':     0,
          'lastOrder': c.createdAt,
          'isNew':     true,
          'imageUrl':  c.imageUrl,
        });
      }
    }

    // Filter
    var filtered = mergedList.where((c) {
      final matchSearch =
          (c['name'] as String).toLowerCase().contains(_search.toLowerCase()) ||
              (c['phone'] as String).contains(_search);
      final matchFilter = _filter == 'all' ||
          (_filter == 'pending' && (c['pending'] as num).toDouble() > 0.5) ||
          (_filter == 'active'  && (c['count']   as int)    > 0);
      return matchSearch && matchFilter;
    }).toList();

    // Summary totals
    final totalCustomers = mergedList.length;
    final totalPending   = mergedList.fold(0.0, (s, c) => s + (c['pending'] as double));
    final totalRevenue   = mergedList.fold(0.0, (s, c) => s + (c['total']   as double));
    final newRegistered  = cp.customers.length;

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Customers ($totalCustomers)', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign_outlined, color: Colors.white),
            tooltip: "Send Bulk WhatsApp Reminders",
            onPressed: () => _sendBulkReminders(context, filtered),
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined, color: Colors.white),
            tooltip: "Reminder History",
            onPressed: () => Navigator.pushNamed(context, '/reminder-history'),
          ),
          PopupMenuButton<String>(
            color: SColors.surface,
            onSelected: (v) => setState(() => _filter = v),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: SRadius.radiusSm,
              ),
              child: const Icon(Icons.filter_list, size: 20, color: Colors.white),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all',     child: Text('All Customers')),
              PopupMenuItem(value: 'active',  child: Text('With Orders')),
              PopupMenuItem(value: 'pending', child: Text('Has Pending')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Live Stats Strip ─────────────────────────────────
          Container(
            color: SColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TopStat('Total', '$totalCustomers', Icons.people),
                _TopStat('Reg.', '$newRegistered', Icons.person_add),
                _TopStat('Pending', 'PKR ${_fmt(totalPending)}', Icons.pending_outlined,
                    color: totalPending > 0 ? Colors.orangeAccent : Colors.greenAccent),
                _TopStat('Revenue', 'PKR ${_fmt(totalRevenue)}', Icons.trending_up,
                    color: Colors.greenAccent),
              ],
            ),
          ),

          // ── Search ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, color: SColors.primary),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _search = ''))
                    : null,
                filled: true,
                fillColor: SColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: const OutlineInputBorder(
                    borderRadius: SRadius.radiusMd,
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // ── Results count ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${filtered.length} customer${filtered.length != 1 ? "s" : ""}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (_filter != 'all')
                  GestureDetector(
                    onTap: () => setState(() => _filter = 'all'),
                    child: Text('Clear filter',
                        style: TextStyle(color: SColors.primary, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Customer List ────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: SColors.textTertiary),
                  const SizedBox(height: 12),
                  const Text('No customers found',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Customers appear when they register or place orders',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _CustomerCard(
                data: filtered[i],
                rank: i + 1,
                onTap: () => _showCustomerDetail(context, filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetail(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomerDetailPage(customerId: data['id'] as String),
      ),
    );
  }

  // NOTE: There's no WhatsApp Business API integration here — sending a
  // message is done by opening WhatsApp with the chat and text pre-filled
  // via a deep link (whatsapp://send or wa.me), which only OPENS the chat.
  // The admin still has to tap Send inside WhatsApp themselves. Firing
  // launchUrl() in a tight loop for N customers (the previous
  // implementation) doesn't work the way "bulk send" implies: each launch
  // just replaces the previous WhatsApp screen before the admin can act on
  // it, so in practice only the last one is ever actually sendable — yet it
  // logged all N as sent successfully. This version sends one at a time and
  // only counts one as sent when the admin confirms they actually sent it.
  Future<void> _sendBulkReminders(BuildContext context, List<Map<String, dynamic>> customers) async {
    final pendingCustomers = customers.where((c) => (c['pending'] as double) > 0).toList();

    if (pendingCustomers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No customers with pending balance")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Send Reminders"),
        content: Text(
          "This opens WhatsApp one customer at a time (${pendingCustomers.length} total) — "
          "you'll confirm each one after sending it, since WhatsApp doesn't let apps send on your behalf.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Start")),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    final rp = context.read<ReminderProvider>();
    final logProvider = context.read<ReminderLogProvider>();
    final sentBy = context.read<AdminUserProvider>().currentUser?.name ?? 'admin';
    int sentCount = 0;
    int index = 0;

    while (index < pendingCustomers.length) {
      if (!context.mounted) break;
      final c = pendingCustomers[index];

      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('Reminder ${index + 1} of ${pendingCustomers.length}'),
          content: Text('${c['name']} — PKR ${(c['pending'] as double).toStringAsFixed(0)} pending.\n\n'
              'Tap "Open WhatsApp", send the message there, then come back and tap "Sent".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'stop'),
              child: const Text('Stop'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'skip'),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                await WhatsAppService.sendPaymentReminder(
                  customerName: c['name'],
                  customerPhone: c['phone'],
                  pendingAmount: (c['pending'] as double),
                  shopName: "Saith Commission Shop",
                );
              },
              child: const Text('Open WhatsApp'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, 'sent'),
              style: ElevatedButton.styleFrom(backgroundColor: SColors.success),
              child: const Text('Sent →'),
            ),
          ],
        ),
      );

      if (action == 'sent') {
        rp.add(ReminderRecord(
          name: c['name'],
          phone: c['phone'],
          amount: (c['pending'] as double),
          time: DateTime.now(),
        ));
        await logProvider.logReminder(ReminderLog(
          id: '',
          customerId: c['id'] as String? ?? '',
          customerName: c['name'] as String,
          customerPhone: c['phone'] as String,
          pendingAmount: c['pending'] as double,
          channel: 'whatsapp',
          status: 'sent',
          message: 'Payment reminder',
          sentBy: sentBy,
          sentAt: DateTime.now(),
        ));
        sentCount++;
        index++;
      } else if (action == 'skip') {
        index++;
      } else {
        break; // 'stop' or dialog dismissed
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Confirmed $sentCount reminder${sentCount == 1 ? '' : 's'} sent"),
      backgroundColor: SColors.success,
    ));
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 100000)  return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Top Stat Widget ────────────────────────────────────────────────────────
class _TopStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _TopStat(this.label, this.value, this.icon,
      {this.color = Colors.white});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ]),
      );
}

// ── Customer Card ──────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int rank;
  final VoidCallback onTap;
  const _CustomerCard(
      {required this.data, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final total   = (data['total']   as num).toDouble();
    final pending = (data['pending'] as num).toDouble();
    final count   = data['count']   as int;
    final isNew   = data['isNew']   as bool? ?? false;
    final imageUrl = data['imageUrl'] as String?;

    String tier = 'Bronze'; Color tierColor = Colors.brown;
    if      (total >= 500000) { tier = 'Platinum'; tierColor = SColors.catPurple; }
    else if (total >= 100000) { tier = 'Gold';     tierColor = Colors.amber.shade700; }
    else if (total >= 50000)  { tier = 'Silver';   tierColor = Colors.blueGrey; }

    final initials = (data['name'] as String)
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: SRadius.radiusLg,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: tierColor.withOpacity(0.12),
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? Text(initials,
                    style: TextStyle(
                        color: tierColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)) : null,
              ),
              if (isNew)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: const BoxDecoration(
                        color: SColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.fiber_new,
                        size: 10, color: Colors.white),
                  ),
                ),
            ]),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: ResponsiveText(data['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 4),
                    _chip(tier, tierColor),
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(data['displayId'] as String,
                        style: const TextStyle(fontSize: 10, color: SColors.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text(data['phone'] as String,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip('$count orders', SColors.primary),
                      if (pending > 0.5)
                        _chip('PKR ${_fmt(pending)} due', SColors.warning)
                      else if (count > 0)
                        _chip('Cleared ✓', SColors.success),
                      if (isNew) _chip('New', SColors.primary),
                    ],
                  ),
                ],
              ),
            ),

            // Total + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('PKR ${_fmt(total)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SColors.primary,
                        fontSize: 14)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: SRadius.radiusSm,
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 100000)  return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Customer Detail Page ───────────────────────────────────────────────────
class _CustomerDetailPage extends StatelessWidget {
  final String customerId;
  const _CustomerDetailPage({required this.customerId});

  @override
  Widget build(BuildContext context) {
    final ip       = context.watch<InvoiceProvider>();
    final cp       = context.watch<CustomerProvider>();
    final lp       = context.watch<LedgerProvider>();

    final customer   = cp.getCustomerById(customerId);
    final invoices   = ip.invoicesByCustomer(customerId);
    final ledger     = lp.entriesForCustomer(customerId);
    final totalSpent = ip.customerTotalSpent(customerId);
    final balance    = ip.customerBalance(customerId);
    final orderCount = invoices.length;
    final pending    = invoices.where((i) => !i.isPaid).length;

    // Tier
    String tier = 'Bronze'; Color tierColor = Colors.brown;
    if      (totalSpent >= 500000) { tier = 'Platinum'; tierColor = SColors.catPurple; }
    else if (totalSpent >= 100000) { tier = 'Gold';     tierColor = Colors.amber.shade700; }
    else if (totalSpent >= 50000)  { tier = 'Silver';   tierColor = Colors.blueGrey; }

    final name  = customer?.name  ?? (invoices.isNotEmpty ? invoices.first.customerName  : 'Unknown');
    final phone = customer?.phone ?? (invoices.isNotEmpty ? invoices.first.customerPhone : '—');
    final email = customer?.email ?? '—';
    final imageUrl = customer?.imageUrl;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 280,
              pinned: true,
              backgroundColor: SColors.primaryLight,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tierColor.withValues(alpha: 0.8),
                        SColors.primaryLight,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // Avatar + name
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ) : null,
                        ),
                        const SizedBox(height: 6),
                        ResponsiveText(name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        Text(phone,
                            style: TextStyle(
                                color: SColors.textOnDarkSub, fontSize: 11)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: tierColor,
                            borderRadius: SRadius.radiusLg,
                          ),
                          child: Text('$tier Member',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ),
                        const SizedBox(height: 12),
                        // KPI row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(child: _headerStat('Orders',   '$orderCount')),
                              Expanded(child: _headerStat('Pending',  '$pending')),
                              Expanded(child: _headerStat('Spent',    'PKR ${_fmt(totalSpent)}')),
                              Expanded(child: _headerStat('Balance',  'PKR ${_fmt(balance)}',
                                  color: balance > 0
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 52), 
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: SColors.primaryLight.withValues(alpha: 0.5),
                  child: const TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Invoices'),
                      Tab(text: 'Ledger'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              // ── Overview Tab ─────────────────────────────────
              _OverviewTab(
                customerId: customerId,
                customer: customer,
                email: email,
                invoices: invoices,
                totalSpent: totalSpent,
                balance: balance,
                tierColor: tierColor,
              ),

              // ── Invoices Tab ──────────────────────────────────
              _InvoicesTab(invoices: invoices),

              // ── Ledger Tab ────────────────────────────────────
              _LedgerTab(entries: ledger, balance: balance),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _headerStat(String label, String value, {Color color = Colors.white}) => Column(children: [
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    ),
    Text(label,
        maxLines: 1,
        style: const TextStyle(color: Colors.white60, fontSize: 9)),
  ]);
}

// ── Overview Tab ──────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final String customerId, email;
  final dynamic customer;
  final List<InvoiceData> invoices;
  final double totalSpent, balance;
  final Color  tierColor;

  const _OverviewTab({
    required this.customerId,
    required this.customer,
    required this.email,
    required this.invoices,
    required this.totalSpent,
    required this.balance,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    final now       = DateTime.now();
    final thisMonth = invoices.where((i) =>
    i.dateTime.month == now.month && i.dateTime.year == now.year);
    final monthTotal = thisMonth.fold(0.0, (s, i) => s + i.grandTotal);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account info card
        _infoCard('Account Information', Icons.person_outline, [
          _infoRow('Customer ID', customerId),
          _infoRow('Email',       email.isEmpty ? 'Not provided' : email),
          _infoRow('Registered',
              customer != null
                  ? _fmtDate(customer!.createdAt as DateTime)
                  : 'via Invoice'),
          _infoRow('Status',
              customer?.isActive == true ? '✅ Active' : '✅ Active'),
        ]),
        const SizedBox(height: 12),

        // Financial summary
        _infoCard('Financial Summary', Icons.payments_outlined, [
          _infoRow('Total Spent',    'PKR ${totalSpent.toStringAsFixed(0)}'),
          _infoRow('Amount Paid',    'PKR ${(totalSpent - balance).toStringAsFixed(0)}'),
          _infoRow('Outstanding',    'PKR ${balance.toStringAsFixed(0)}',
              valueColor: balance > 0 ? SColors.warning : SColors.success),
          _infoRow('This Month',     'PKR ${monthTotal.toStringAsFixed(0)}'),
          _infoRow('Total Orders',   '${invoices.length}'),
          _infoRow('Paid Orders',
              '${invoices.where((i) => i.isPaid).length}'),
          _infoRow('Pending Orders',
              '${invoices.where((i) => !i.isPaid).length}',
              valueColor: invoices.any((i) => !i.isPaid)
                  ? SColors.warning : SColors.success),
        ]),
        const SizedBox(height: 12),

        // Loyalty progress
        _infoCard('Loyalty Status', Icons.workspace_premium, [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Tier',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.1),
                          borderRadius: SRadius.radiusMd,
                        ),
                        child: Text(
                            totalSpent >= 500000 ? 'Platinum'
                                : totalSpent >= 100000 ? 'Gold'
                                : totalSpent >= 50000  ? 'Silver'
                                : 'Bronze',
                            style: TextStyle(
                                color: tierColor, fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: SRadius.radiusSm,
                  child: LinearProgressIndicator(
                    value: (totalSpent /
                        (totalSpent >= 100000 ? 500000 : 100000))
                        .clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: SColors.border,
                    valueColor: AlwaysStoppedAnimation(tierColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PKR ${totalSpent.toStringAsFixed(0)} spent  ·  '
                      'Loyalty points: ${(totalSpent / 100).floor()}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Quick actions for admin
        _infoCard('Quick Actions', Icons.flash_on_outlined, [
          Row(children: [
            Expanded(
              child: _actionBtn(
                'New Invoice',
                Icons.receipt_long_outlined,
                SColors.success,
                    () => Navigator.pushNamed(context, '/admin-invoice'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                'Reminder',
                Icons.notifications_outlined,
                SColors.warning,
                    () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment reminder sent'))),
              ),
            ),
          ]),
        ]),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  Widget _infoRow(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: valueColor ?? Colors.black87),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: SRadius.radiusMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _infoCard(String title, IconData icon, List<Widget> children) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SRadius.radiusLg,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: SColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
}

// ── Invoices Tab ───────────────────────────────────────────────────────────
class _InvoicesTab extends StatelessWidget {
  final List<InvoiceData> invoices;
  const _InvoicesTab({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text('No invoices yet', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: invoices.length,
      itemBuilder: (_, i) {
        final inv = invoices[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerInvoiceDetailPage(invoice: inv),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: SRadius.radiusMd,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(inv.invoiceNo,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: inv.isPaid
                                ? SColors.success.withValues(alpha: 0.1)
                                : SColors.warning.withValues(alpha: 0.1),
                            borderRadius: SRadius.radiusMd,
                          ),
                          child: Text(inv.isPaid ? 'Paid' : 'Pending',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: inv.isPaid ? SColors.success : SColors.warning)),
                        ),
                      ]),
                  const SizedBox(height: 6),
                  Text(
                    '${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year}  ·  '
                        '${inv.products.length} item${inv.products.length != 1 ? "s" : ""}  ·  '
                        '${inv.paymentMethod.toUpperCase()}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  // Products
                  ...inv.products.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p.name,
                            style: const TextStyle(fontSize: 12)),
                        Text(
                            '${p.quantity.toStringAsFixed(0)} bags × PKR ${((p.pricePer40kg / 40) * (p.weightPerUnit > 0 ? p.weightPerUnit : 50)).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  )),
                  const Divider(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total: PKR ${inv.grandTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: SColors.primary,
                                fontSize: 14)),
                        if (!inv.isPaid)
                          Text(
                            'Due: PKR ${(inv.grandTotal - inv.amountPaid).toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 12, color: SColors.warning),
                          ),
                      ]),
                  // Mark as paid button
                  if (!inv.isPaid) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<InvoiceProvider>().markAsPaid(inv.invoiceNo);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${inv.invoiceNo} marked as paid'),
                              backgroundColor: SColors.success,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Mark as Paid',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: SRadius.radiusSm),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Ledger Tab ─────────────────────────────────────────────────────────────
class _LedgerTab extends StatelessWidget {
  final List entries;
  final double balance;
  const _LedgerTab({required this.entries, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Balance banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          color: balance > 0
              ? SColors.catOrange
              : SColors.primary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Outstanding Balance',
                    style: TextStyle(color: SColors.textOnDarkSub, fontSize: 12)),
                Text('PKR ${balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ]),
              Icon(
                balance > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
                color: Colors.white, size: 32,
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
            child: Text('No ledger entries yet',
                style: TextStyle(color: Colors.grey)),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e       = entries[i];
              final isDebit = e.debit > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: SRadius.radiusMd,
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6)],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDebit
                          ? SColors.error.withValues(alpha: 0.1)
                          : SColors.success.withValues(alpha: 0.1),
                      borderRadius: SRadius.radiusMd,
                    ),
                    child: Icon(
                      isDebit
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isDebit ? SColors.error : SColors.success,
                      size: 18,
                    ),
                  ),
                  title: Text(e.description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(
                    '${e.dateTime.day}/${e.dateTime.month}/${e.dateTime.year}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isDebit
                            ? '+ PKR ${e.debit.toStringAsFixed(0)}'
                            : '- PKR ${e.credit.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDebit ? SColors.error : SColors.success,
                            fontSize: 13),
                      ),
                      Text('Bal: PKR ${e.balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
