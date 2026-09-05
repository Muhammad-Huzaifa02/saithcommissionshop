import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/data/repositories/advanced_analytics_service.dart';
import 'package:saithcommissionshop/core/utils/overflow_handler.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Analytics'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Sales'),
            Tab(text: 'Stock'),
            Tab(text: 'Customers'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: ResponsiveOverflowHandler(
        child: TabBarView(
          controller: _tabs,
          children: const [
            _SalesTab(),
            _StockTab(),
            _CustomerTab(),
            _InsightsTab(),
          ],
        ),
      ),
    );
  }
}

// 📊 SALES TAB (LIVE + FILTER + ANIMATION)

enum DateFilter { daily, weekly, monthly, yearly }

class _SalesTab extends StatefulWidget {
  const _SalesTab();

  @override
  State<_SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<_SalesTab> {
  DateFilter filter = DateFilter.monthly;

  List<FlSpot> _buildChartData(InvoiceProvider ip) {
    final now = DateTime.now();
    final map = <int, double>{};

    for (final inv in ip.invoices) {
      bool match = false;

      switch (filter) {
        case DateFilter.daily:
          match = inv.dateTime.day == now.day;
          break;

        case DateFilter.weekly:
          match = now.difference(inv.dateTime).inDays <= 7;
          break;

        case DateFilter.monthly:
          match = inv.dateTime.month == now.month;
          break;

        case DateFilter.yearly:
          match = inv.dateTime.year == now.year;
          break;
      }

      if (match) {
        final key = filter == DateFilter.daily ? inv.dateTime.hour : inv.dateTime.day;

        map[key] = (map[key] ?? 0) + inv.grandTotal;
      }
    }

    return map.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();
    final spots = _buildChartData(ip);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // FILTER
        Row(
          children: [
            const Text("Filter: "),
            const SizedBox(width: 10),
            DropdownButton<DateFilter>(
              value: filter,
              onChanged: (v) => setState(() => filter = v!),
              items: const [
                DropdownMenuItem(value: DateFilter.daily, child: Text("Daily")),
                DropdownMenuItem(value: DateFilter.weekly, child: Text("Weekly")),
                DropdownMenuItem(value: DateFilter.monthly, child: Text("Monthly")),
                DropdownMenuItem(value: DateFilter.yearly, child: Text("Yearly")),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ANIMATED CHART
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: SizedBox(
            key: ValueKey(filter),
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: SColors.success,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 📦 STOCK TAB (UNCHANGED BUT SAFE)

class _StockTab extends StatelessWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Stock Overview (${pp.products.length})"),
      ],
    );
  }
}

// 👥 CUSTOMER TAB (SEARCH + FILTER)

class _CustomerTab extends StatefulWidget {
  const _CustomerTab();

  @override
  State<_CustomerTab> createState() => _CustomerTabState();
}

class _CustomerTabState extends State<_CustomerTab> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();
    final customers = ip.customerSummaries;

    final filtered = customers.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SEARCH BOX
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: "Search customer...",
          ),
          onChanged: (v) => setState(() => query = v),
        ),

        const SizedBox(height: 16),

        // LIST
        ...filtered.map((c) => Card(
              child: ListTile(
                title: Text(c['name']),
                subtitle: Text("Total: ${c['total']}"),
              ),
            )),
      ],
    );
  }
}

// 🔎 INSIGHTS TAB (forecast, product performance, margins, growth, LTV)
// All figures here come from real invoice + purchase-price data via
// AdvancedAnalyticsService — no hardcoded cost assumptions or random values.

class _InsightsTab extends StatelessWidget {
  const _InsightsTab();

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();
    final pp = context.watch<ProductProvider>();
    final invoices = ip.invoices;
    final products = pp.products;

    if (invoices.isEmpty) {
      return const Center(child: Text('Not enough sales data yet'));
    }

    final now = DateTime.now();
    final periodStart = now.subtract(const Duration(days: 30));
    final prevPeriodStart = now.subtract(const Duration(days: 60));
    final current = invoices.where((i) => !i.dateTime.isBefore(periodStart)).toList();
    final previous = invoices
        .where((i) => i.dateTime.isBefore(periodStart) && !i.dateTime.isBefore(prevPeriodStart))
        .toList();
    final growthRate = AdvancedAnalyticsService.calculateGrowthRate(current, previous);

    final forecasts = AdvancedAnalyticsService.forecastSales(invoices, 7);
    final forecastTotal = forecasts.fold(0.0, (s, f) => s + f.predictedSales);

    final performance = AdvancedAnalyticsService.analyzeProductPerformance(invoices, products)
        .take(5)
        .toList();

    final margins = AdvancedAnalyticsService.analyzeProfitMargins(invoices, 'monthly', products)
        .take(3)
        .toList();

    final ltv = AdvancedAnalyticsService.calculateCustomerLTV(invoices).take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Next 7 Days (est.)',
                'PKR ${forecastTotal.toStringAsFixed(0)}',
                Icons.trending_up,
                SColors.catBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                '30-Day Growth',
                '${growthRate >= 0 ? '+' : ''}${growthRate.toStringAsFixed(1)}%',
                growthRate >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                growthRate >= 0 ? SColors.success : SColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Forecast is a simple trend estimate, not a guarantee — treat it as a rough planning number.',
          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),

        const SizedBox(height: 24),
        const Text('Top Products (last activity)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (performance.isEmpty) const Text('No product sales yet'),
        ...performance.map((p) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('#${p.rank}')),
                title: Text(p.productName),
                subtitle: Text('${p.unitsSold} sold · margin ${p.profitMargin.toStringAsFixed(1)}%'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PKR ${p.totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${p.growthRate >= 0 ? '+' : ''}${p.growthRate.toStringAsFixed(0)}% (30d)',
                      style: TextStyle(
                        fontSize: 11,
                        color: p.growthRate >= 0 ? SColors.success : SColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            )),

        const SizedBox(height: 24),
        const Text('Profit by Month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (margins.isEmpty) const Text('No data yet'),
        ...margins.map((m) => Card(
              child: ListTile(
                title: Text(m.period),
                subtitle: Text('Revenue PKR ${m.revenue.toStringAsFixed(0)} · Costs PKR ${m.costs.toStringAsFixed(0)}'),
                trailing: Text(
                  'PKR ${m.netProfit.toStringAsFixed(0)}\n${m.marginPercentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: m.netProfit >= 0 ? SColors.success : SColors.error,
                  ),
                ),
              ),
            )),

        const SizedBox(height: 24),
        const Text('Top Customers (lifetime value)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (ltv.isEmpty) const Text('No customers yet'),
        ...ltv.map((c) => Card(
              child: ListTile(
                title: Text(c.customerName),
                subtitle: Text('${c.orderCount} orders · ${c.tier}'),
                trailing: Text('PKR ${c.totalSpent.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      );
}

