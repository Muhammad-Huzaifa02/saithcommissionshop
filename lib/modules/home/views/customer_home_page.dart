// customer_home_page.dart  —  Saith Commission Shop

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';
import 'package:saithcommissionshop/modules/home/providers/weather_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/cart/providers/cart_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/modules/orders/views/customer_invoice_pages.dart';

// ─────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────
class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});
  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetch();
    });
  }

  Future<void> _launchWhatsApp() async {
    final url = Uri.parse(
        "https://wa.me/923055496500?text=${Uri.encodeComponent('Hello! I need support with Saith Commission Shop.')}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().currentCustomer;
    context.read<InvoiceProvider>().initialize(customer?.id, false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
        final action = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: SColors.background,
            shape: const RoundedRectangleBorder(
                borderRadius: SRadius.radiusLg),
            title: Text('Leave Shop?',
                style: SText.headingMd.copyWith(
                    color: SColors.textPrimary)),
            content: Text(
                'Do you want to sign out and go back?',
                style: SText.bodyMd.copyWith(
                    color: SColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'stay'),
                child: Text('Stay',
                    style: SText.labelLg.copyWith(
                        color: SColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                      borderRadius: SRadius.radiusMd),
                ),
                child: Text('Sign Out', style: SText.labelLg),
              ),
            ],
          ),
        );
        if (action == 'logout' && mounted) {
          if (!context.mounted) return;
          context.read<CustomerProvider>().logout();
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
              children: [
                _DashboardTab(
                  onSupport:  _launchWhatsApp,
                  onNavigate: (i) => setState(() => _selectedIndex = i),
                ),
                const _ShopTab(),
                const _OrdersTab(),
                _MoreTab(
                    onNavigate: (i) => setState(() => _selectedIndex = i)),
              ],
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

        // WhatsApp FAB
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70), // Lift above floating nav
          child: SizedBox(
            width: 52, height: 52,
            child: FloatingActionButton(
              onPressed: _launchWhatsApp,
              backgroundColor: const Color(0xFF25D366),
              elevation: 4,
              shape: const CircleBorder(),
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/1200px-WhatsApp.svg.png',
                width: 28, height: 28,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.chat, color: Colors.white, size: 26),
              ),
            ),
          ),
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
          _NavIcon(0, Icons.home_outlined, Icons.home, 'Home', selectedIndex, onChanged),
          _NavIcon(1, Icons.shopping_bag_outlined, Icons.shopping_bag, 'Shop', selectedIndex, onChanged),
          _NavIcon(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Orders', selectedIndex, onChanged),
          _NavIcon(3, Icons.person_outline, Icons.person, 'Account', selectedIndex, onChanged),
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
  final VoidCallback   onSupport;
  final Function(int)  onNavigate;
  const _DashboardTab(
      {required this.onSupport, required this.onNavigate});
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {

  @override
  Widget build(BuildContext context) {
    final customer     = context.watch<CustomerProvider>().currentCustomer;
    final ip           = context.watch<InvoiceProvider>();
    final lp           = context.watch<LedgerProvider>();
    final myInvoices   = customer != null
        ? ip.invoicesByCustomer(customer.id)
        : <InvoiceData>[];
    final balance      = customer != null
        ? lp.customerBalance(customer.id)
        : 0.0;
    final totalSpent   = myInvoices.fold(0.0, (s, i) => s + i.grandTotal);

    return Scaffold(
      backgroundColor: SColors.background,
      body: CustomScrollView(slivers: [
        // ── Header ───────────────────────────────────────────
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
                      // Header Row
                      const SizedBox(height: 10),
                      Row(children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customer?.name ?? 'Muhammad Huzaifa',
                                style: SText.headingMd.copyWith(color: Colors.white)),
                            Text(customer?.phone ?? '0305-9099500',
                                style: SText.bodyXs.copyWith(color: Colors.white70)),
                          ],
                        ),
                        const Spacer(),
                        _CircularIcon(Icons.shopping_bag_outlined, () => Navigator.pushNamed(context, '/cart')),
                        const SizedBox(width: 10),
                        _CircularIcon(Icons.notifications_outlined, () => Navigator.pushNamed(context, '/notifications')),
                        const SizedBox(width: 10),
                        _CircularIcon(Icons.menu, () {}),
                      ]),
                      
                      const SizedBox(height: 16),
                      // Tier Chip
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_tierIcon(totalSpent), color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(_tier(totalSpent).toUpperCase(), style: SText.labelXs.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // 3D Balance Card
                      _GlassBalanceCard(balance: balance),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Main Content ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: SColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Business Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _StatTile('Active', '${myInvoices.where((i) => !i.isPaid).length}', 'Orders', Icons.receipt_long),
                      const SizedBox(width: 12),
                      _StatTile('Spent', SPkr.compact(totalSpent), 'Lifetime', Icons.payments),
                      const SizedBox(width: 12),
                      _StatTile('Points', '${(totalSpent/100).floor()}', 'Loyalty', Icons.stars),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionPill('Market Rates', Icons.show_chart, () => Navigator.pushNamed(context, '/price-board')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionPill('Order History', Icons.history, () => widget.onNavigate(2)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                // Recent Orders List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SSectionHeader(title: 'RECENT ACTIVITY'),
                      const SizedBox(height: 16),
                      if (myInvoices.isEmpty)
                        _StatCard('No recent activity', 'Start shopping to see your history', Icons.history_toggle_off)
                      else
                        ...myInvoices.take(3).map((inv) => _RecentOrderTile(invoice: inv)),
                    ],
                  ),
                ),
                const SizedBox(height: 120), 
              ],
            ),
          ),
        ),
      ]),
    );
  }

  String _tier(double totalSpent) {
    if (totalSpent >= 500000) return 'Platinum';
    if (totalSpent >= 100000) return 'Gold';
    if (totalSpent >= 50000)  return 'Silver';
    return 'Bronze';
  }

  IconData _tierIcon(double totalSpent) {
    if (totalSpent >= 500000) return Icons.diamond;
    if (totalSpent >= 100000) return Icons.emoji_events;
    if (totalSpent >= 50000)  return Icons.military_tech;
    return Icons.workspace_premium;
  }

}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionPill(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: SShadow.neoOut,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: SColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: SText.labelMd),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// TAB 2 — SHOP
// ─────────────────────────────────────────────────────────────
class _ShopTab extends StatefulWidget {
  const _ShopTab();
  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  String _search   = '';
  String _category = 'all';

  static const _categories = [
    'all', 'Basmati', 'Kernel', 'Sella', 'IRRI'
  ];

  @override
  Widget build(BuildContext context) {
    final products  = context.watch<ProductProvider>().products;
    final cartCount = context.watch<CartProvider>().itemCount;
    final customer  = context.watch<CustomerProvider>().currentCustomer;
    final lp        = context.watch<LedgerProvider>();
    final pendingAmt = customer != null
        ? lp.customerBalance(customer.id)
        : 0.0;

    final filtered = products.where((p) {
      final ms = p.name.toLowerCase().contains(_search.toLowerCase());
      final mc = _category == 'all' ||
          (p.category ?? '').contains(_category);
      return ms && mc;
    }).toList();

    return Scaffold(
      backgroundColor: SColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: true,
          backgroundColor: SColors.primary,
          title: Text('Shop Rice',
              style: SText.headingMd.copyWith(color: Colors.white)),
          actions: [
            Stack(children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.white, size: 24),
                onPressed: () =>
                    Navigator.pushNamed(context, '/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 17, height: 17,
                    decoration: const BoxDecoration(
                        color: SColors.error,
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text('$cartCount',
                          style: SText.labelXs
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ),
            ]),
          ],
        ),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                SSpacing.md, SSpacing.md, SSpacing.md, SSpacing.sm),
            child: TextField(
              style: SText.bodyMd
                  .copyWith(color: SColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search rice varieties...',
                hintStyle: SText.bodyMd
                    .copyWith(color: SColors.textTertiary),
                prefixIcon: Icon(Icons.search,
                    color: SColors.textSecondary, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            size: 18,
                            color: SColors.textTertiary),
                        onPressed: () =>
                            setState(() => _search = ''))
                    : null,
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
        ),

        // Category chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: SSpacing.md),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = _category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: SSpacing.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSpacing.md,
                          vertical: SSpacing.xs),
                      decoration: BoxDecoration(
                        color: sel
                            ? SColors.primary
                            : SColors.surface,
                        borderRadius: SRadius.radiusFull,
                        border: Border.all(
                            color: sel
                                ? SColors.primary
                                : SColors.border,
                            width: 0.5),
                      ),
                      child: Text(
                        cat == 'all' ? 'All Rice' : cat,
                        style: SText.labelMd.copyWith(
                            color: sel
                                ? Colors.white
                                : SColors.textSecondary),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Pending due banner
        if (pendingAmt > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  SSpacing.md, SSpacing.md, SSpacing.md, 0),
              child: Container(
                padding: SSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: SColors.warningBg,
                  borderRadius: SRadius.radiusMd,
                  border: Border.all(
                      color: SColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: SColors.warning, size: 18),
                  const SizedBox(width: SSpacing.sm),
                  Expanded(
                    child: Text(
                      '${SPkr.format(pendingAmt)} payment due',
                      style: SText.bodySm.copyWith(
                          color: SColors.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
            ),
          ),

        // Count row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                SSpacing.md, SSpacing.md, SSpacing.md, SSpacing.sm),
            child: Text(
              '${filtered.length} Products Available',
              style: SText.headingSm
                  .copyWith(color: SColors.textPrimary),
            ),
          ),
        ),

        // Product grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              SSpacing.md, 0, SSpacing.md, 100),
          sliver: filtered.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text('No products found',
                        style: TextStyle(
                            color: SColors.textTertiary)),
                  ),
                )
              : SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.74,
                    mainAxisSpacing: SSpacing.md,
                    crossAxisSpacing: SSpacing.md,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ProductCard(product: filtered[i]),
                    childCount: filtered.length,
                  ),
                ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 3 — ORDERS
// ─────────────────────────────────────────────────────────────
class _OrdersTab extends StatefulWidget {
  const _OrdersTab();
  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  String _filter = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final ip       = context.watch<InvoiceProvider>();
    final customer = context.watch<CustomerProvider>().currentCustomer;
    final all      = customer != null
        ? ip.invoicesByCustomer(customer.id)
        : <InvoiceData>[];

    final filtered = all.where((inv) {
      final mf = _filter == 'all' ||
          (_filter == 'paid' && inv.isPaid) ||
          (_filter == 'pending' && !inv.isPaid);
      final ms = _search.isEmpty ||
          inv.invoiceNo.toLowerCase().contains(_search.toLowerCase());
      return mf && ms;
    }).toList();

    final totalSpent   = all.fold(0.0, (s, i) => s + i.grandTotal);
    final totalPending = all
        .where((i) => !i.isPaid)
        .fold(0.0, (s, i) => s + i.grandTotal);

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('My Orders',
            style: SText.headingMd.copyWith(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            shape: RoundedRectangleBorder(
                borderRadius: SRadius.radiusMd),
            icon: Container(
              padding: const EdgeInsets.all(SSpacing.xs + 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: SRadius.radiusSm,
              ),
              child: const Icon(Icons.filter_list,
                  color: Colors.white, size: 20),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'all',
                  child: Text('All Orders', style: SText.bodyMd)),
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
          const SizedBox(width: SSpacing.xs),
        ],
      ),
      body: Column(children: [
        // Stats strip
        Container(
          decoration:
              const BoxDecoration(gradient: SGradient.primarySoft),
          padding: const EdgeInsets.symmetric(vertical: SSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat('Total Orders', '${all.length}', Colors.white),
              Container(
                  width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _Stat('Total Spent', SPkr.format(totalSpent),
                  SColors.primaryXLight),
              Container(
                  width: 0.5, height: 32,
                  color: Colors.white.withValues(alpha: 0.3)),
              _Stat(
                  'Due',
                  SPkr.format(totalPending),
                  totalPending > 0
                      ? SColors.gold
                      : SColors.primaryXLight),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.all(SSpacing.md),
          child: TextField(
            style: SText.bodyMd.copyWith(color: SColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search order number...',
              hintStyle: SText.bodyMd
                  .copyWith(color: SColors.textTertiary),
              prefixIcon: Icon(Icons.search,
                  color: SColors.textSecondary, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear,
                          size: 16, color: SColors.textTertiary),
                      onPressed: () => setState(() => _search = ''))
                  : null,
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

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 56, color: SColors.textTertiary),
                      const SizedBox(height: SSpacing.md),
                      Text('No orders found',
                          style: SText.bodyMd.copyWith(
                              color: SColors.textTertiary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      SSpacing.md, 0, SSpacing.md, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _OrderCard(invoice: filtered[i]),
                ),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: SText.amountXs.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            style:
                SText.labelXs.copyWith(color: SColors.textOnDarkSub)),
      ]);
}

// ── Order card ────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final InvoiceData invoice;
  const _OrderCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final inv    = invoice;
    final isPaid = inv.isPaid;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  CustomerInvoiceDetailPage(invoice: inv))),
      child: Container(
        margin: const EdgeInsets.only(bottom: SSpacing.md),
        padding: SSpacing.cardPadding,
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: SRadius.radiusMd,
          boxShadow: SShadow.neoOut,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${inv.invoiceNo}',
                          style: SText.headingSm.copyWith(
                              color: SColors.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      Text(
                        '${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year}',
                        style: SText.bodyXs.copyWith(
                            color: SColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SStatusBadge(
                    status: isPaid ? 'paid' : 'pending'),
              ],
            ),

            Divider(
                height: SSpacing.lg,
                thickness: 0.5,
                color: SColors.divider),

            // Products
            ...inv.products.map((p) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: SSpacing.xs),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(p.name,
                              style: SText.bodySm.copyWith(
                                  color: SColors.textPrimary),
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: SSpacing.sm),
                      Text(
                        '${p.quantity.toStringAsFixed(0)} bags × PKR ${((p.pricePer40kg / 40) * (p.weightPerUnit > 0 ? p.weightPerUnit : 50)).toStringAsFixed(0)}',
                        style: SText.bodyXs.copyWith(
                            color: SColors.textSecondary),
                      ),
                    ],
                  ),
                )),

            Divider(
                height: SSpacing.lg,
                thickness: 0.5,
                color: SColors.divider),

            // Total + PDF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: PKR ${inv.grandTotal.toStringAsFixed(0)}',
                        style: SText.amountXs.copyWith(
                            color: SColors.primary),
                      ),
                      if (!isPaid)
                        Text(
                          'Due: PKR ${(inv.grandTotal - inv.amountPaid).toStringAsFixed(0)}',
                          style: SText.bodyXs.copyWith(
                              color: SColors.warning),
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _downloadPdf(context, inv),
                  icon: const Icon(Icons.download_outlined,
                      size: 15),
                  label: Text('PDF', style: SText.labelMd),
                  style: TextButton.styleFrom(
                    foregroundColor: SColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: SSpacing.sm,
                        vertical: SSpacing.xs),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext ctx, InvoiceData inv) async {
    try {
      final msg = ScaffoldMessenger.of(ctx);
      msg.showSnackBar(SnackBar(
        content: Text('Generating PDF...',
            style: SText.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: SColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: SRadius.radiusMd),
        margin: const EdgeInsets.all(SSpacing.md),
        duration: const Duration(seconds: 1),
      ));
      final file = await PdfInvoiceService.generate(inv);
      if (!ctx.mounted) return;
      msg.showSnackBar(SnackBar(
        content: Text('Saved: ${file.path.split('/').last}',
            style: SText.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: SColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: SRadius.radiusMd),
        margin: const EdgeInsets.all(SSpacing.md),
      ));
    } catch (e) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Error: $e',
            style: SText.bodyMd.copyWith(color: Colors.white)),
        backgroundColor: SColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(SSpacing.md),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 4 — MORE
// ─────────────────────────────────────────────────────────────
class _MoreTab extends StatelessWidget {
  final Function(int) onNavigate;
  const _MoreTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().currentCustomer;
    final lp       = context.watch<LedgerProvider>();
    final balance  = customer != null
        ? lp.customerBalance(customer.id)
        : 0.0;

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('More',
            style: SText.headingMd.copyWith(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(SSpacing.md),
        children: [
          // Profile card
          Container(
            padding: SSpacing.cardPadding,
            decoration: const BoxDecoration(
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
                  child: customer?.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                              customer!.imageUrl!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover))
                      : Text(
                          (customer?.name ?? 'C')[0].toUpperCase(),
                          style: SText.headingMd
                              .copyWith(color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(width: SSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer?.name ?? 'Customer',
                        style: SText.headingMd
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(customer?.phone ?? '',
                        style: SText.bodyXs.copyWith(
                            color: SColors.textOnDarkSub)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: SRadius.radiusFull,
                      ),
                      child: Text('CUSTOMER ACCOUNT',
                          style: SText.labelXs.copyWith(
                              color: SColors.textOnDark)),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: SSpacing.lg),

          // Account section
          _MoreSection('Account', [
            _MoreItem(Icons.person_outline, 'My Profile',
                'View & edit details', SColors.catGreen,
                onTap: () => Navigator.pushNamed(
                    context, '/customer-profile')),
            _MoreItem(
                Icons.account_balance_wallet_outlined,
                'Ledger',
                'Balance: ${SPkr.format(balance)}',
                SColors.catBlue,
                onTap: () => Navigator.pushNamed(
                      context,
                      '/customer-ledger',
                      arguments: {
                        'customerId': customer?.id,
                        'customerName': customer?.name,
                      },
                    )),
            _MoreItem(Icons.history, 'Order History',
                'View past purchases', SColors.catOrange,
                onTap: () => onNavigate(2)),
          ]),

          const SizedBox(height: SSpacing.md),

          _MoreSection('Support', [
            _MoreItem(Icons.notifications_outlined, 'Notifications',
                'App updates', SColors.catGold,
                onTap: () => Navigator.pushNamed(
                    context, '/notifications')),
            _MoreItem(Icons.help_outline, 'Help & FAQ',
                'Common questions', SColors.catPurple,
                onTap: () =>
                    Navigator.pushNamed(context, '/help')),
            _MoreItem(Icons.info_outline, 'About Shop',
                'Version & terms', SColors.catTeal,
                onTap: () =>
                    Navigator.pushNamed(context, '/about')),
          ]),

          const SizedBox(height: SSpacing.lg),

          // Sign out
          GestureDetector(
            onTap: () {
              context.read<CustomerProvider>().logout();
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
                SIconBox(icon: Icons.logout, color: SColors.error),
                const SizedBox(width: SSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign Out',
                          style: SText.headingSm
                              .copyWith(color: SColors.error)),
                      Text('Logged in as Customer',
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
  final String       title;
  final List<_MoreItem> items;
  const _MoreSection(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SSectionHeader(
            title: title,
            padding:
                const EdgeInsets.only(bottom: SSpacing.sm)),
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
                  shape: const RoundedRectangleBorder(
                      borderRadius: SRadius.radiusMd),
                  contentPadding: SSpacing.listItemPadding,
                  leading: SIconBox(
                      icon: item.icon,
                      color: item.color,
                      size: 38,
                      iconSize: 18),
                  title: Text(item.title,
                      style: SText.headingSm.copyWith(
                          color: SColors.textPrimary)),
                  subtitle: Text(item.subtitle,
                      style: SText.bodyXs.copyWith(
                          color: SColors.textSecondary)),
                  trailing: Icon(Icons.chevron_right,
                      color: SColors.textTertiary, size: 18),
                  onTap: item.onTap,
                ),
                if (!isLast)
                  const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: SColors.divider,
                      indent: SSpacing.md + 38 + SSpacing.md),
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
  final String   title, subtitle;
  final Color    color;
  final VoidCallback? onTap;
  const _MoreItem(this.icon, this.title, this.subtitle, this.color,
      {this.onTap});
}

// ─────────────────────────────────────────────────────────────
// PRODUCT CARD
// ─────────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});
  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  bool  _added = false;
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (widget.product.isOutOfStock) return;
    context.read<CartProvider>().addProduct(InvoiceProduct(
      name:         widget.product.name,
      productId:    widget.product.id,
      pricePer40kg: widget.product.pricePer40kg,
      quantity:     1,
      weightPerUnit: 50,
    ));
    setState(() => _added = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _added = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 16),
        const SizedBox(width: SSpacing.sm),
        Expanded(
          child: Text(
            '${widget.product.name} added to cart',
            style: SText.bodyMd.copyWith(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      backgroundColor: SColors.success,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: SRadius.radiusMd),
      margin: const EdgeInsets.all(SSpacing.md),
    ));
  }

  void _openDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(
        product:     widget.product,
        onAddToCart: _addToCart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final statusColor = p.isOutOfStock
        ? SColors.textTertiary
        : p.isLowStock
            ? SColors.warning
            : SColors.success;
    final bgColor = p.isOutOfStock
        ? SColors.surfaceAlt
        : p.isLowStock
            ? SColors.warningBg
            : SColors.successBg;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () {
          _ctrl.forward();
          _openDetail();
          _ctrl.reverse();
        },
        child: Container(
          decoration: BoxDecoration(
            color: SColors.surface,
            borderRadius: SRadius.radiusMd,
            boxShadow: SShadow.neoOut,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              Expanded(
                flex: 5,
                child: Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(SRadius.md)),
                    ),
                    width: double.infinity,
                    child: Center(
                      child: Icon(Icons.grain,
                          size: 48, color: statusColor),
                    ),
                  ),
                  // Status badge
                  if (p.isOutOfStock)
                    Positioned(
                      top: SSpacing.sm, left: SSpacing.sm,
                      child: _StatusBadge('Out of Stock',
                          SColors.textTertiary),
                    ),
                  if (p.isLowStock && !p.isOutOfStock)
                    Positioned(
                      top: SSpacing.sm, left: SSpacing.sm,
                      child: _StatusBadge('Low Stock', SColors.warning),
                    ),
                  // Added overlay
                  if (_added)
                    Container(
                      decoration: BoxDecoration(
                        color: SColors.primary.withValues(alpha: 0.88),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(SRadius.md)),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle,
                            color: Colors.white, size: 40),
                      ),
                    ),
                  // View hint
                  Positioned(
                    bottom: SSpacing.sm, right: SSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSpacing.xs + 2,
                          vertical: SSpacing.xxs + 1),
                      decoration: BoxDecoration(
                        color:
                            SColors.textPrimary.withValues(alpha: 0.22),
                        borderRadius: SRadius.radiusXs,
                      ),
                      child: Text('View',
                          style: SText.labelXs
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ]),
              ),

              // Info area
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    SSpacing.sm, SSpacing.sm,
                    SSpacing.sm, SSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.name,
                        style: SText.headingSm.copyWith(
                            color: SColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${p.stockBags.toStringAsFixed(0)} bags · PKR ${p.pricePer40kg.toStringAsFixed(0)}',
                      style: SText.bodyXs.copyWith(
                          color: p.isLowStock
                              ? SColors.warning
                              : SColors.textSecondary),
                    ),
                    const SizedBox(height: SSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: p.isOutOfStock ? null : _addToCart,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          backgroundColor: p.isOutOfStock
                              ? SColors.border
                              : SColors.primary,
                          disabledBackgroundColor: SColors.border,
                          shape: RoundedRectangleBorder(
                              borderRadius: SRadius.radiusSm),
                        ),
                        child: Text(
                          p.isOutOfStock
                              ? 'Out of Stock'
                              : 'Add to Cart',
                          style: SText.labelXs.copyWith(
                              color: p.isOutOfStock
                                  ? SColors.textTertiary
                                  : Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _StatusBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: SSpacing.sm - 1,
            vertical: SSpacing.xxs + 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: SRadius.radiusXs,
        ),
        child: Text(label,
            style: SText.labelXs.copyWith(color: Colors.white)),
      );
}

// ─────────────────────────────────────────────────────────────
// PRODUCT DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _ProductDetailSheet extends StatefulWidget {
  final Product      product;
  final VoidCallback onAddToCart;
  const _ProductDetailSheet(
      {required this.product, required this.onAddToCart});
  @override
  State<_ProductDetailSheet> createState() =>
      _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  double _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p         = widget.product;
    final statusColor = p.isOutOfStock
        ? SColors.textTertiary
        : p.isLowStock
            ? SColors.warning
            : SColors.success;
    final bgColor = p.isOutOfStock
        ? SColors.surfaceAlt
        : p.isLowStock
            ? SColors.warningBg
            : SColors.successBg;

    final pricePer50kg = p.pricePer40kg / 40 * 50;
    final totalPrice   = pricePer50kg * _qty;
    final totalKg      = 50 * _qty;
    final maxQty       = p.isOutOfStock
        ? 0.0
        : (p.availableStockKg / 50).floorToDouble();

    return Container(
      decoration: const BoxDecoration(
        color: SColors.surface,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(SRadius.xl)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              SSpacing.md),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: SSpacing.sm),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: SColors.border,
            borderRadius: SRadius.radiusFull,
          ),
        ),
        const SizedBox(height: SSpacing.md),

        // Image
        Container(
          height: 130,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(
              horizontal: SSpacing.lg),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: SRadius.radiusMd,
          ),
          child: Stack(children: [
            Center(child: Icon(Icons.grain,
                size: 68, color: statusColor)),
            if (p.isOutOfStock)
              Positioned(
                top: SSpacing.sm, right: SSpacing.sm,
                child: _StatusBadge('Out of Stock',
                    SColors.textTertiary),
              )
            else if (p.isLowStock)
              Positioned(
                top: SSpacing.sm, right: SSpacing.sm,
                child: _StatusBadge('Low Stock', SColors.warning),
              ),
          ]),
        ),
        const SizedBox(height: SSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: SSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(p.name,
                        style: SText.headingLg.copyWith(
                            color: SColors.textPrimary)),
                  ),
                  if (p.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSpacing.sm,
                          vertical: SSpacing.xxs + 1),
                      decoration: BoxDecoration(
                        color: SColors.primaryBg,
                        borderRadius: SRadius.radiusFull,
                      ),
                      child: Text(p.category!,
                          style: SText.labelSm
                              .copyWith(color: SColors.primary)),
                    ),
                ],
              ),
              const SizedBox(height: SSpacing.md),

              // Price info grid
              Row(children: [
                _InfoBox('Price / 40 Kg',
                    'PKR ${p.pricePer40kg.toStringAsFixed(0)}',
                    Icons.payments_outlined, SColors.catGreen),
                const SizedBox(width: SSpacing.sm),
                _InfoBox('Price / 50 Kg Bag',
                    'PKR ${pricePer50kg.toStringAsFixed(0)}',
                    Icons.shopping_bag_outlined, SColors.catOrange),
              ]),
              const SizedBox(height: SSpacing.sm),
              Row(children: [
                _InfoBox('Weight / Bag', '50 kg',
                    Icons.scale_outlined, SColors.catBlue),
                const SizedBox(width: SSpacing.sm),
                _InfoBox(
                    'Stock',
                    '${p.stockBags.toStringAsFixed(0)} bags',
                    Icons.inventory_2_outlined,
                    statusColor),
              ]),

              if (!p.isOutOfStock) ...[
                const SizedBox(height: SSpacing.md),
                Text('Select Quantity (bags)',
                    style: SText.headingSm.copyWith(
                        color: SColors.textPrimary)),
                const SizedBox(height: SSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QtyBtn(Icons.remove, () {
                      if (_qty > 1) setState(() => _qty--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SSpacing.xl),
                      child: Column(children: [
                        Text('${_qty.toInt()}',
                            style: SText.displayMd.copyWith(
                                color: SColors.textPrimary)),
                        Text('bags',
                            style: SText.labelMd.copyWith(
                                color: SColors.textSecondary)),
                      ]),
                    ),
                    _QtyBtn(Icons.add, () {
                      if (_qty < maxQty) setState(() => _qty++);
                    }),
                  ],
                ),
                const SizedBox(height: SSpacing.sm),
                Center(
                  child: Text(
                    '${totalKg.toStringAsFixed(0)} kg  ·  PKR ${totalPrice.toStringAsFixed(0)} total',
                    style: SText.amountSm.copyWith(
                        color: SColors.primary),
                  ),
                ),
                const SizedBox(height: SSpacing.md),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<CartProvider>().addProduct(
                            InvoiceProduct(
                              name:          p.name,
                              productId:     p.id,
                              pricePer40kg:  p.pricePer40kg,
                              quantity:      _qty,
                              weightPerUnit: 50,
                            ),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_qty.toInt()} bag(s) of ${p.name} added to cart',
                            style: SText.bodyMd
                                .copyWith(color: Colors.white),
                          ),
                          backgroundColor: SColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: SRadius.radiusMd),
                          margin: const EdgeInsets.all(SSpacing.md),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined,
                        size: 18),
                    label: Text(
                      'Add to Cart — PKR ${totalPrice.toStringAsFixed(0)}',
                      style: SText.labelLg.copyWith(
                          fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: SRadius.radiusMd),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: SSpacing.md),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.remove_shopping_cart),
                    label: Text('Out of Stock',
                        style: SText.labelLg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SColors.border,
                      foregroundColor: SColors.textTertiary,
                      shape: RoundedRectangleBorder(
                          borderRadius: SRadius.radiusMd),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: SSpacing.sm),
      ]),
    );
  }

  Widget _InfoBox(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(SSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: SRadius.radiusSm,
            border: Border.all(
                color: color.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: SSpacing.xs),
                Expanded(
                  child: Text(label,
                      style: SText.labelXs.copyWith(
                          color: SColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: SSpacing.xxs + 1),
              Text(value,
                  style: SText.amountXs.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );

  Widget _QtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: SColors.primaryBg,
            borderRadius: SRadius.radiusSm,
            border: Border.all(
                color: SColors.primary.withValues(alpha: 0.3),
                width: 0.5),
          ),
          child: Icon(icon, color: SColors.primary, size: 22),
        ),
      );
}

// ── CUSTOM DASHBOARD WIDGETS ──────────────────────────────────

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

class _GlassBalanceCard extends StatelessWidget {
  final double balance;
  const _GlassBalanceCard({required this.balance});

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
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Balance', style: SText.bodySm.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('PKR', style: SText.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(SPkr.compact(balance).replaceAll('PKR', '').trim(), 
                style: SText.displayMd.copyWith(color: Colors.white, fontSize: 32)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _GlassBtn('ADD PAYMENT', SColors.primaryXLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassBtn('SHOP NOW', Colors.white.withOpacity(0.9), isOutlined: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _GlassBtn(String label, Color color, {bool isOutlined = false}) {
    return Container(
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
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  const _StatTile(this.label, this.value, this.sub, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: SColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: SShadow.neoOut,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: SText.bodyXs.copyWith(color: Colors.white60)),
                Icon(icon, size: 16, color: SColors.primary.withOpacity(0.4)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: SText.headingMd.copyWith(fontSize: 18, color: Colors.white)),
            Text(sub, style: SText.bodyXs.copyWith(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}


class _RecentOrderTile extends StatelessWidget {
  final InvoiceData invoice;
  const _RecentOrderTile({required this.invoice});

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
              color: SColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long, color: SColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${invoice.invoiceNo}', style: SText.headingSm.copyWith(color: Colors.white)),
                Text('${invoice.dateTime.day}/${invoice.dateTime.month} · ${invoice.products.length} items', 
                  style: SText.bodyXs.copyWith(color: Colors.white54)),
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

class _StatCard extends StatelessWidget {
  final String title, sub;
  final IconData icon;
  const _StatCard(this.title, this.sub, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(title, style: SText.bodyMd.copyWith(fontWeight: FontWeight.bold)),
          Text(sub, style: SText.bodyXs.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}
