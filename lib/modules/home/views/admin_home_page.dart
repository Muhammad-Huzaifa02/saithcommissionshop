
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/home/providers/weather_provider.dart';
import 'package:saithcommissionshop/data/services/stock_alert_service.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/modules/orders/views/customer_invoice_pages.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// ROOT — AdminHomePage with bottom nav
// ─────────────────────────────────────────────────────────────
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetch();
    });
  }

  static const _tabs = [
    _DashboardTab(),
    _InvoicesTab(),
    _StockTab(),
    _MoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    context.read<InvoiceProvider>().initialize(null, true);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // If not on Dashboard, go back to Dashboard first
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        final action = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: SRadius.radiusLg),
            title: Text('Sign Out?',
                style: SText.headingMd
                    .copyWith(color: SColors.textPrimary)),
            content: Text(
                'Do you want to sign out and return to role selection?',
                style: SText.bodyMd
                    .copyWith(color: SColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'stay'),
                child: Text('Stay',
                    style: SText.labelLg
                        .copyWith(color: SColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'logout'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: SColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                        borderRadius: SRadius.radiusMd)),
                child: const Text('Sign Out', style: SText.labelLg),
              ),
            ],
          ),
        );
        if (action == 'logout') {
          if (!mounted || !context.mounted) return;
          context.read<AdminUserProvider>().logout();
          Navigator.pushNamedAndRemoveUntil(
              context, '/role-selection', (_) => false);
        }
      },
      child: Scaffold(
        backgroundColor: SColors.background,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _tabs,
            ),

            // Floating Bottom Nav
            Positioned(
              left: 16, right: 16, bottom: 20,
              child: _FloatingBottomNav(
                selectedIndex: _selectedIndex,
                onChanged: (i) => setState(() => _selectedIndex = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating Bottom Navigation ────────────────────────────────
class _FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FloatingBottomNav({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: SColors.border.withOpacity(0.5), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', selectedIndex, onChanged),
          _NavIcon(1, Icons.receipt_long_outlined, Icons.receipt_long, 'Invoices', selectedIndex, onChanged),
          _NavIcon(2, Icons.inventory_2_outlined, Icons.inventory_2, 'Stock', selectedIndex, onChanged),
          _NavIcon(3, Icons.more_horiz_outlined, Icons.more_horiz, 'More', selectedIndex, onChanged),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final int index;
  final IconData icon, activeIcon;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _NavIcon(this.index, this.icon, this.activeIcon, this.label, this.selectedIndex, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? SColors.primary : SColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? SColors.primary : SColors.textSecondary,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — DASHBOARD
// ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  int _touchedBar = -1;

  @override
  Widget build(BuildContext context) {
    final admin   = context.watch<AdminUserProvider>().currentUser;
    final ip      = context.watch<InvoiceProvider>();
    final pp      = context.watch<ProductProvider>();
    final cp      = context.watch<CustomerProvider>();
    final alerts  = StockAlertService.checkStockAlerts(pp.products);
    final now     = DateTime.now();
    final monthly = ip.monthlySales;

    return Scaffold(
      backgroundColor: SColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 280,
            pinned: true,
            backgroundColor: SColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: SGradient.primary),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(admin?.name ?? 'Admin Dashboard',
                                  style: SText.headingMd.copyWith(color: Colors.white)),
                            ],
                          ),
                          const Spacer(),
                          _CircularIcon(Icons.notifications_outlined, () => Navigator.pushNamed(context, '/notifications')),
                          const SizedBox(width: 10),
                          _CircularIcon(Icons.analytics_outlined, () => Navigator.pushNamed(context, '/admin-analytics')),
                        ]),
                        
                        const SizedBox(height: 32),
                        // 3D Glass Stats Card
                        _GlassAdminSummary(ip: ip, now: now, monthly: monthly),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: SColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  children: [
                    // KPI Row 1
                    Row(children: [
                      _AdminKpiTile('Sales', SPkr.format(ip.totalSales), '+12%', Icons.trending_up, SColors.catGreen),
                      const SizedBox(width: 12),
                      _AdminKpiTile('Customers', '${cp.totalCustomers}', 'Total', Icons.people, SColors.catBlue),
                    ]),
                    const SizedBox(height: 12),
                    // KPI Row 2
                    Row(children: [
                      _AdminKpiTile('Pending', SPkr.format(ip.totalPending), '${ip.pendingCount} inv', Icons.pending, SColors.catOrange),
                      const SizedBox(width: 12),
                      _AdminKpiTile('Stock Val', SPkr.format(pp.totalStockValue), 'Total', Icons.inventory, SColors.catPurple),
                    ]),

                    if (alerts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _AdminStockAlert(alerts: alerts),
                    ],

                    const SizedBox(height: 32),
                    _SalesChart(
                      monthly: monthly,
                      now: now,
                      touchedBar: _touchedBar,
                      onTouch: (i) => setState(() => _touchedBar = i),
                    ),

                    const SizedBox(height: 32),
                    SSectionHeader(
                      title: 'Recent Invoices',
                      padding: EdgeInsets.zero,
                      trailing: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/invoices'),
                        child: Text('View All', style: TextStyle(color: SColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...ip.invoices.take(5).map((inv) => _AdminInvoiceTile(invoice: inv)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ── Monthly sales bar chart ───────────────────────────────────
class _SalesChart extends StatelessWidget {
  final Map<int, double> monthly;
  final DateTime now;
  final int touchedBar;
  final ValueChanged<int> onTouch;

  const _SalesChart({
    required this.monthly,
    required this.now,
    required this.touchedBar,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SSpacing.cardPadding,
      decoration: BoxDecoration(
        color: SColors.surface,
        borderRadius: SRadius.radiusMd,
        border: Border.all(color: SColors.border, width: 0.5),
        boxShadow: SShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Sales',
                  style: SText.headingSm
                      .copyWith(color: SColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: SSpacing.sm,
                    vertical: SSpacing.xxs + 1),
                decoration: BoxDecoration(
                  color: SColors.primaryBg,
                  borderRadius: SRadius.radiusFull,
                ),
                child: Text('${now.year}',
                    style: SText.labelSm
                        .copyWith(color: SColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: SSpacing.md),
          SizedBox(
            height: 180,
            child: monthly.isEmpty
                ? Center(
                    child: Text('No data yet',
                        style: SText.bodyMd.copyWith(
                            color: SColors.textTertiary)))
                : BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: monthly.values
                            .fold(0.0, (a, b) => a > b ? a : b) *
                        1.3 +
                        1,
                    barTouchData: BarTouchData(
                      touchCallback: (_, response) => onTouch(
                          response?.spot
                                  ?.touchedBarGroupIndex ??
                              -1),
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, __) =>
                            BarTooltipItem(
                          SPkr.format(rod.toY),
                          SText.labelSm.copyWith(
                              color: Colors.white),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const months = [
                              '', 'J', 'F', 'M', 'A', 'M',
                              'J', 'J', 'A', 'S', 'O', 'N', 'D'
                            ];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(top: 4),
                              child: Text(
                                v.toInt() < months.length
                                    ? months[v.toInt()]
                                    : '',
                                style: SText.labelXs.copyWith(
                                    color: SColors.textTertiary),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (v, _) => Text(
                            SPkr.compact(v),
                            style: SText.labelXs.copyWith(
                                color: SColors.textTertiary),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: SColors.border,
                        strokeWidth: 0.5,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(12, (i) {
                      final m   = i + 1;
                      final val = monthly[m] ?? 0.0;
                      final touched = touchedBar == i;
                      return BarChartGroupData(
                        x: m,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            color: touched
                                ? SColors.gold
                                : SColors.primary,
                            width: touched ? 18 : 13,
                            borderRadius: SRadius.radiusXs,
                          )
                        ],
                      );
                    }),
                  )),
          ),
        ],
      ),
    );
  }
}



// ── Invoice list tile ─────────────────────────────────────────
class _InvoiceTile extends StatelessWidget {
  final dynamic invoice;
  final VoidCallback onTap;
  const _InvoiceTile({required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPaid = invoice.isPaid as bool;
    final color  = isPaid ? SColors.success : SColors.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: SSpacing.listItemPadding,
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: SRadius.radiusMd,
          border: Border.all(color: SColors.border, width: 0.5),
          boxShadow: SShadow.card,
        ),
        child: Row(children: [
          SIconBox(
            icon: isPaid
                ? Icons.check_circle_outline
                : Icons.pending_outlined,
            color: color,
          ),
          const SizedBox(width: SSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.customerName as String,
                    style: SText.headingSm
                        .copyWith(color: SColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${invoice.customerDisplayId ?? "GUEST"} · ${invoice.invoiceNo} · ${invoice.dateTime.day}/${invoice.dateTime.month}/${invoice.dateTime.year}',
                  style: SText.bodyXs
                      .copyWith(color: SColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${(invoice.grandTotal as double).toStringAsFixed(0)}',
                style: SText.amountXs
                    .copyWith(color: SColors.textPrimary),
              ),
              const SizedBox(height: 3),
              SStatusBadge(
                  status: isPaid ? 'paid' : 'pending'),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — INVOICES
// ─────────────────────────────────────────────────────────────
class _InvoicesTab extends StatefulWidget {
  const _InvoicesTab();
  @override
  State<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends State<_InvoicesTab> {
  String _filter = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoiceProvider>().invoices;
    final filtered = invoices.where((inv) {
      final mf = _filter == 'all' ||
          (_filter == 'paid' && inv.isPaid) ||
          (_filter == 'pending' && !inv.isPaid);
      final ms = inv.customerName
              .toLowerCase()
              .contains(_search.toLowerCase()) ||
          inv.invoiceNo.contains(_search);
      return mf && ms;
    }).toList();

    final total   = invoices.fold(0.0, (s, i) => s + i.grandTotal);
    final paid    = invoices.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);
    final pending = invoices.where((i) => !i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Invoices',
            style: SText.headingMd.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, '/admin-invoice'),
            tooltip: 'New Invoice',
          ),
        ],
      ),
      body: Column(children: [
        // Summary strip
        Container(
          decoration: const BoxDecoration(
              gradient: SGradient.primarySoft),
          padding: const EdgeInsets.symmetric(
              vertical: SSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InvStat('Total',   SPkr.format(total),   Colors.white),
              Container(width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _InvStat('Paid',    SPkr.format(paid),    SColors.primaryXLight),
              Container(width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _InvStat('Pending', SPkr.format(pending), SColors.gold),
            ],
          ),
        ),

        // Search + filter
        Padding(
          padding: const EdgeInsets.all(SSpacing.md),
          child: Row(children: [
            Expanded(
              child: TextField(
                style: SText.bodyMd
                    .copyWith(color: SColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search by name or invoice no...',
                  hintStyle: SText.bodyMd
                      .copyWith(color: SColors.textTertiary),
                  prefixIcon: Icon(Icons.search,
                      color: SColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: SColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: SSpacing.md,
                      vertical: SSpacing.sm + SSpacing.xs),
                  border: OutlineInputBorder(
                      borderRadius: SRadius.radiusMd,
                      borderSide: BorderSide(
                          color: SColors.border, width: 0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: SRadius.radiusMd,
                      borderSide: BorderSide(
                          color: SColors.border, width: 0.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: SRadius.radiusMd,
                      borderSide: BorderSide(
                          color: SColors.primary, width: 1.5)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: SSpacing.sm),
            PopupMenuButton<String>(
              onSelected: (v) => setState(() => _filter = v),
              shape: const RoundedRectangleBorder(
                  borderRadius: SRadius.radiusMd),
              icon: Container(
                padding: const EdgeInsets.all(SSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: SColors.surface,
                  borderRadius: SRadius.radiusMd,
                  border: Border.all(
                      color: SColors.border, width: 0.5),
                ),
                child: Icon(Icons.filter_list,
                    color: SColors.primary, size: 20),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'all',
                    child: Text('All',
                        style: SText.bodyMd)),
                PopupMenuItem(
                    value: 'paid',
                    child: Text('Paid',
                        style: SText.bodyMd
                            .copyWith(color: SColors.success))),
                PopupMenuItem(
                    value: 'pending',
                    child: Text('Pending',
                        style: SText.bodyMd
                            .copyWith(color: SColors.warning))),
              ],
            ),
          ]),
        ),

        // Invoice list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No invoices found',
                      style: SText.bodyMd.copyWith(
                          color: SColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      SSpacing.md, 0,
                      SSpacing.md, SSpacing.md),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final inv = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: SSpacing.sm),
                      child: _InvoiceTile(
                        invoice: inv,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerInvoiceDetailPage(
                                    invoice: inv),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _InvStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InvStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: SText.amountXs.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: SText.labelXs
                .copyWith(color: SColors.textOnDarkSub)),
      ]);
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — STOCK
// ─────────────────────────────────────────────────────────────
class _StockTab extends StatelessWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final summary  = StockAlertService.getStockSummary(products);

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Stock',
            style: SText.headingMd.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Colors.white),
            onPressed: () =>
                Navigator.pushNamed(context, '/admin-stock'),
          ),
        ],
      ),
      body: Column(children: [
        // Summary strip
        Container(
          decoration: const BoxDecoration(
              gradient: SGradient.primarySoft),
          padding: const EdgeInsets.symmetric(
              vertical: SSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StockStat('Healthy', '${summary['healthy']}',  SColors.primaryXLight),
              Container(width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _StockStat('Low',     '${summary['lowStock']}', SColors.gold),
              Container(width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _StockStat('Out',     '${summary['outOfStock']}',SColors.error),
              Container(width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _StockStat('Total',   '${summary['total']}',    Colors.white),
            ],
          ),
        ),

        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Text('No products yet',
                      style: SText.bodyMd.copyWith(
                          color: SColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(SSpacing.md),
                  itemCount: products.length,
                  itemBuilder: (_, i) =>
                      _StockProductCard(product: products[i]),
                ),
        ),
      ]),
    );
  }
}

class _StockStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StockStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: SText.amountMd.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: SText.labelXs
                .copyWith(color: SColors.textOnDarkSub)),
      ]);
}

class _StockProductCard extends StatelessWidget {
  final dynamic product;
  const _StockProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p   = product;
    final pct = (p.availableStockKg / 2000).clamp(0.0, 1.0);
    final clr = p.isOutOfStock
        ? SColors.error
        : p.isLowStock
            ? SColors.warning
            : SColors.success;
    final statusLabel = p.isOutOfStock
        ? 'Out of Stock'
        : p.isLowStock
            ? 'Low Stock'
            : 'Healthy';

    return Padding(
      padding: const EdgeInsets.only(bottom: SSpacing.sm),
      child: Container(
        padding: SSpacing.cardPadding,
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: SRadius.radiusMd,
          border: Border.all(color: SColors.border, width: 0.5),
          boxShadow: SShadow.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              SIconBox(icon: Icons.grain, color: clr),
              const SizedBox(width: SSpacing.md),
              Expanded(
                child: Text(p.name as String,
                    style: SText.headingSm
                        .copyWith(color: SColors.textPrimary)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(p.availableStockKg as double).toStringAsFixed(0)} kg',
                    style: SText.amountXs.copyWith(color: clr),
                  ),
                  Text(
                    '${(p.stockBags as double).toStringAsFixed(0)} bags',
                    style: SText.bodyXs.copyWith(
                        color: SColors.textSecondary),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: SSpacing.md),
            ClipRRect(
              borderRadius: SRadius.radiusXs,
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 6,
                backgroundColor: SColors.border,
                valueColor: AlwaysStoppedAnimation(clr),
              ),
            ),
            const SizedBox(height: SSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PKR ${(p.pricePer40kg as double).toStringAsFixed(0)} / 40kg',
                  style: SText.bodyXs
                      .copyWith(color: SColors.textSecondary),
                ),
                SStatusBadge(
                    status: p.isOutOfStock
                        ? 'overdue'
                        : p.isLowStock
                            ? 'pending'
                            : 'paid',
                    label: statusLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 4 — MORE
// ─────────────────────────────────────────────────────────────
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminUserProvider>().currentUser;

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SSpacing.md),
        children: [
          // Admin profile card
          Container(
            padding: SSpacing.cardPadding,
            decoration: BoxDecoration(
              gradient: SGradient.primarySoft,
              borderRadius: SRadius.radiusMd,
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: Center(
                  child: Text(
                    (admin?.name ?? 'A')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: SText.headingMd,
                  ),
                ),
              ),
              const SizedBox(width: SSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin?.name ?? 'Admin',
                        style: SText.headingMd),
                    const SizedBox(height: 2),
                    Text(admin?.email ?? '',
                        style: SText.bodyXs),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSpacing.sm,
                          vertical: SSpacing.xxs + 1),
                      decoration: BoxDecoration(
                        color:
                            SColors.primary.withOpacity(0.1),
                        borderRadius: SRadius.radiusFull,
                      ),
                      child: Text(
                        (admin?.role.name ?? 'ADMIN')
                            .toUpperCase(),
                        style: SText.labelXs,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: SSpacing.lg),

          // Menu sections
          _MoreSection('Management', const [
            _MoreItem(Icons.inventory_2_outlined, 'Products',      'Manage rice catalog',      '/admin-products',  SColors.catGreen),
            _MoreItem(Icons.people_outline,       'Customers',     'View & manage customers',  '/admin-customers', SColors.catBlue),
            _MoreItem(Icons.table_chart_outlined, 'Price Board',   'Update mandi rates',       '/price-board',     SColors.catBlue),
            _MoreItem(Icons.local_shipping_outlined,'Suppliers',   'Supplier database',        '/admin-suppliers', SColors.catOrange),
            _MoreItem(Icons.add_shopping_cart,    'New Invoice',   'Create manual invoice',    '/admin-invoice',   SColors.catTeal),
          ]),

          const SizedBox(height: SSpacing.md),

          _MoreSection('Reports & History', const [
            _MoreItem(Icons.trending_up,           'Profit Analysis','Revenue & margins',      '/admin-profit',   SColors.catGreen),
            _MoreItem(Icons.receipt_long_outlined, 'All Invoices',  'View invoice list',       '/invoices',       SColors.catIndigo),
          ]),

          const SizedBox(height: SSpacing.md),

          _MoreSection('System', const [
            _MoreItem(Icons.settings_outlined,      'Settings',      'App configuration',      '/admin-settings', SColors.textSecondary),
            _MoreItem(Icons.notifications_outlined, 'Notifications', 'Alerts & reminders',     '/notifications',  SColors.gold),
          ]),

          const SizedBox(height: SSpacing.lg),

          // Sign out
          GestureDetector(
            onTap: () {
              context.read<AdminUserProvider>().logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/role-selection', (_) => false);
            },
            child: Container(
              padding: SSpacing.cardPadding,
              decoration: BoxDecoration(
                color: SColors.errorBg,
                borderRadius: SRadius.radiusMd,
                border: Border.all(
                    color: SColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                SIconBox(
                    icon: Icons.logout, color: SColors.error),
                const SizedBox(width: SSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign Out',
                          style: SText.headingSm
                              .copyWith(color: SColors.error)),
                      Text('Logged in as Admin',
                          style: SText.bodyXs.copyWith(
                              color: SColors.error
                                  .withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: SColors.error, size: 20),
              ]),
            ),
          ),

          const SizedBox(height: SSpacing.xl),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  final String title;
  final List<_MoreItem> items;
  const _MoreSection(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SSectionHeader(
          title: title,
          padding: const EdgeInsets.only(bottom: SSpacing.sm),
        ),
        Container(
          decoration: BoxDecoration(
            color: SColors.surface,
            borderRadius: SRadius.radiusMd,
            boxShadow: SShadow.neoOut,
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              final item   = e.value;
              return Column(children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: SRadius.radiusMd),
                  contentPadding: SSpacing.listItemPadding,
                  leading: SIconBox(
                      icon: item.icon,
                      color: item.color,
                      size: 38,
                      iconSize: 18),
                  title: Text(item.title,
                      style: SText.headingSm),
                  subtitle: Text(item.subtitle,
                      style: SText.bodyXs),
                  trailing: Icon(Icons.chevron_right,
                      color: SColors.textTertiary, size: 18),
                  onTap: () =>
                      Navigator.pushNamed(context, item.route),
                ),
                if (!isLast)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: SColors.divider,
                    indent: SSpacing.md +
                        38 +
                        SSpacing.md, // align with text
                  ),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String   title, subtitle, route;
  final Color    color;
  const _MoreItem(
      this.icon, this.title, this.subtitle, this.route, this.color);
}

// ── ADMIN DASHBOARD WIDGETS ───────────────────────────────────

class _CircularIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularIcon(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _GlassAdminSummary extends StatelessWidget {
  final InvoiceProvider ip;
  final DateTime now;
  final Map<int, double> monthly;

  const _GlassAdminSummary({required this.ip, required this.now, required this.monthly});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Performance', style: SText.bodySm.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PKR', style: SText.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(SPkr.compact(ip.dailyTotal()).replaceAll('PKR', '').trim(), 
                style: SText.displayMd.copyWith(color: Colors.white, fontSize: 32)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _AdminGlassBtn('NEW INVOICE', SColors.primaryXLight, () => Navigator.pushNamed(context, '/admin-invoice'))),
              const SizedBox(width: 12),
              Expanded(child: _AdminGlassBtn('REPORTS', Colors.white.withOpacity(0.9), () => Navigator.pushNamed(context, '/admin-profit'), isOutlined: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _AdminGlassBtn(String label, Color color, VoidCallback onTap, {bool isOutlined = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(22),
          border: isOutlined ? Border.all(color: Colors.white.withOpacity(0.8), width: 1.5) : null,
        ),
        child: Center(
          child: Text(label, style: SText.labelMd.copyWith(
            color: isOutlined ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          )),
        ),
      ),
    );
  }
}

class _AdminKpiTile extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  const _AdminKpiTile(this.label, this.value, this.trend, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: SSpacing.cardPadding,
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: SShadow.neoOut,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, size: 18, color: color),
                ),
                Text(trend, style: SText.labelXs.copyWith(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(label, style: SText.bodyXs.copyWith(color: Colors.white60)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: SText.headingMd.copyWith(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStockAlert extends StatelessWidget {
  final List alerts;
  const _AdminStockAlert({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: SColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${alerts.length} Low Stock Alerts', style: SText.headingSm.copyWith(color: SColors.error)),
                Text('Manage inventory to prevent outages', style: SText.bodyXs.copyWith(color: SColors.error.withOpacity(0.8))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/admin-stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('FIX NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AdminInvoiceTile extends StatelessWidget {
  final InvoiceData invoice;
  const _AdminInvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
        boxShadow: SShadow.neoOut,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: invoice.isPaid ? SColors.success.withOpacity(0.1) : SColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(invoice.isPaid ? Icons.check_circle_outline : Icons.pending_outlined, 
              color: invoice.isPaid ? SColors.success : SColors.warning, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.customerName, style: SText.headingSm.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('#${invoice.invoiceNo} · ${invoice.dateTime.day}/${invoice.dateTime.month}', 
                  style: SText.bodyXs.copyWith(color: Colors.white60)),
              ],
            ),
          ),
          Text('PKR ${invoice.grandTotal.toStringAsFixed(0)}', 
            style: SText.amountXs.copyWith(color: SColors.primary)),
        ],
      ),
    );
  }
}
