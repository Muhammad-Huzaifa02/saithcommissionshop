import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/data/services/export_service.dart';
import 'package:saithcommissionshop/data/services/whatsapp_service.dart';
import 'package:saithcommissionshop/data/services/monthly_report_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});
  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final Map<String, bool> _loading = {};

  void _setLoading(String key, bool v) =>
      setState(() => _loading[key] = v);

  bool _isLoading(String key) => _loading[key] == true;

  // ── Excel Exports ──────────────────────────────────────────────────────────
  Future<void> _exportInvoices() async {
    _setLoading('invoices', true);
    try {
      final invoices = context.read<InvoiceProvider>().invoices;
      if (invoices.isEmpty) { 
        if (!mounted) return;
        _snack('No invoices to export', SColors.warning); return; 
      }
      final file = await ExportService.exportInvoicesToExcel(List.from(invoices));
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Invoices — Saith Commission Shop',
          text: 'All invoices exported — ${invoices.length} records');
      if (!mounted) return;
      _snack('Invoices exported successfully ✓', SColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack('Export failed: $e', SColors.error);
    } finally { _setLoading('invoices', false); }
  }

  Future<void> _exportProducts() async {
    _setLoading('products', true);
    try {
      final products = context.read<ProductProvider>().products;
      if (products.isEmpty) { 
        if (!mounted) return;
        _snack('No products to export', SColors.warning); return; 
      }
      final file = await ExportService.exportProductsToExcel(List.from(products));
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Products — Saith Commission Shop',
          text: 'Products stock list — ${products.length} items');
      if (!mounted || !context.mounted) return;
      _snack('Products exported successfully ✓', SColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack('Export failed: $e', SColors.error);
    } finally { _setLoading('products', false); }
  }

  Future<void> _exportCustomerLedger() async {
    _setLoading('ledger', true);
    try {
      final customers = context.read<CustomerProvider>().customers;
      if (customers.isEmpty) { 
        if (!mounted) return;
        _snack('No customers found', SColors.warning); return; 
      }

      // Export summary CSV of all customers
      final invoices = context.read<InvoiceProvider>().invoices;
      final file = await ExportService.exportSummaryCSV(List.from(invoices));
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Customer Summary — Saith Commission Shop');
      if (!mounted || !context.mounted) return;
      _snack('Customer ledger exported ✓', SColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack('Export failed: $e', SColors.error);
    } finally { _setLoading('ledger', false); }
  }

  // ── PDF Reports ────────────────────────────────────────────────────────────
  Future<void> _exportMonthlyReport() async {
    _setLoading('monthly', true);
    try {
      final ip   = context.read<InvoiceProvider>();
      final pp   = context.read<ProductProvider>();
      final now  = DateTime.now();
      final file = await MonthlyReportService.generateMonthlyReport(
        invoices: List.from(ip.invoices),
        products: List.from(pp.products),
        month:    now.month,
        year:     now.year,
      );
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Monthly Report — ${_monthName(now.month)} ${now.year}',
          text: 'Monthly sales report for ${_monthName(now.month)} ${now.year}');
      if (!mounted) return;
      _snack('Monthly report generated ✓', SColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', SColors.error);
    } finally { _setLoading('monthly', false); }
  }

  Future<void> _exportFullSummaryCSV() async {
    _setLoading('csv', true);
    try {
      final invoices = context.read<InvoiceProvider>().invoices;
      if (invoices.isEmpty) { 
        if (!mounted) return;
        _snack('No data to export', SColors.warning); return; 
      }
      final file = await ExportService.exportSummaryCSV(List.from(invoices));
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Sales Summary CSV — Saith Commission Shop');
      if (!mounted) return;
      _snack('CSV exported ✓', SColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', SColors.error);
    } finally { _setLoading('csv', false); }
  }

  // ── WhatsApp ───────────────────────────────────────────────────────────────
  Future<void> _sendPaymentReminders() async {
    _setLoading('wa_reminders', true);
    try {
      final ip        = context.read<InvoiceProvider>();
      final pending   = ip.pendingInvoices();
      if (pending.isEmpty) { 
        if (!mounted) return;
        _snack('No pending payments', SColors.warning); return; 
      }

      int sent = 0;
      for (final inv in pending.take(5)) {
        final ok = await WhatsAppService.sendPaymentReminder(
          customerName:  inv.customerName,
          customerPhone: inv.customerPhone,
          pendingAmount: inv.grandTotal - inv.amountPaid,
          shopName:      'Saith Commission Shop',
        );
        if (ok) sent++;
        await Future.delayed(const Duration(milliseconds: 800));
      }
      if (!mounted || !context.mounted) return;
      _snack('Reminders sent to $sent customers', SColors.success);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', SColors.error);
    } finally { _setLoading('wa_reminders', false); }
  }

  Future<void> _sendLowStockAlert() async {
    _setLoading('wa_stock', true);
    try {
      final pp  = context.read<ProductProvider>();
      final low = [...pp.lowStockProducts, ...pp.outOfStockProducts];
      if (low.isEmpty) { 
        if (!mounted) return;
        _snack('All products are well-stocked ✓', SColors.success); return; 
      }

      final items = low.map((p) => {
        'name': p.name, 'stock': p.availableStockKg.toStringAsFixed(0),
      }).toList();

      // Open WhatsApp alert (shows admin what to send)
      if (!mounted) return;
      _showStockAlertDialog(items);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', SColors.error);
    } finally { _setLoading('wa_stock', false); }
  }


  void _showStockAlertDialog(List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Low Stock Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${items.length} product(s) need restocking:',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.warning_amber, color: SColors.warning, size: 16),
                const SizedBox(width: 6),
                Text('${i['name']} — ${i['stock']} kg',
                    style: const TextStyle(fontSize: 13)),
              ]),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await WhatsAppService.sendLowStockAlert(
                adminPhone:    '',  // Admin enters own number in settings
                lowStockItems: items,
                shopName:      'Saith Commission Shop',
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Send via WhatsApp'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color,
            behavior: SnackBarBehavior.floating));
  }

  static String _monthName(int m) {
    const names = ['','January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    return names[m];
  }

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();
    final pp = context.watch<ProductProvider>();
    final cp = context.watch<CustomerProvider>();
    final lp = context.watch<LedgerProvider>();

    final totalInvoices  = ip.invoices.length;
    final totalProducts  = pp.products.length;
    final totalCustomers = cp.totalCustomers;
    final pendingCount   = ip.pendingCount;
    final lowStockCount  = pp.lowStockCount + pp.outOfStockCount;
    final totalLedger    = lp.entries.length;

    return AppPageScaffold(
      title: 'Export & Share',
      scrollable: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: SSpacing.md, vertical: SSpacing.md),
        children: [
          // ── Stats overview ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(SSpacing.md),
            decoration: const BoxDecoration(
              gradient: SGradient.todayStrip,
              borderRadius: SRadius.radiusLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OverviewStat('Invoices', '$totalInvoices', Icons.receipt_long),
                _OverviewStat('Stock', '$totalProducts', Icons.inventory_2),
                _OverviewStat('Ledger', '$totalLedger', Icons.account_balance_wallet_outlined),
                _OverviewStat('Pending', PakistanFormatter.formatPKR(ip.totalPending),
                    Icons.pending_outlined),
              ],
            ),
          ),
          const SizedBox(height: SSpacing.lg),

          // ── Excel Section ────────────────────────────────────────────
          _SectionHeader('Excel Export', Icons.table_chart, SColors.success),
          const SizedBox(height: SSpacing.sm),
          _ExportCard(
            icon: Icons.receipt_long_outlined,
            title: 'All Invoices',
            subtitle: '$totalInvoices invoices with full details',
            color: SColors.success,
            isLoading: _isLoading('invoices'),
            onTap: _exportInvoices,
          ),
          _ExportCard(
            icon: Icons.inventory_2_outlined,
            title: 'Products & Stock',
            subtitle: '$totalProducts products with prices and stock',
            color: Colors.teal,
            isLoading: _isLoading('products'),
            onTap: _exportProducts,
          ),
          _ExportCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Customer Ledger Summary',
            subtitle: '$totalCustomers customers, pending balances',
            color: SColors.catBlue,
            isLoading: _isLoading('ledger'),
            onTap: _exportCustomerLedger,
          ),
          const SizedBox(height: SSpacing.lg),

          // ── PDF Section ──────────────────────────────────────────────
          _SectionHeader('PDF Reports', Icons.picture_as_pdf, SColors.error),
          const SizedBox(height: SSpacing.sm),
          _ExportCard(
            icon: Icons.summarize_outlined,
            title: 'Monthly Sales Report',
            subtitle: 'Full PDF with charts and breakdown',
            color: SColors.error,
            isLoading: _isLoading('monthly'),
            onTap: _exportMonthlyReport,
          ),
          _ExportCard(
            icon: Icons.table_rows_outlined,
            title: 'Sales Summary CSV',
            subtitle: 'Quick CSV for spreadsheet import',
            color: SColors.warning,
            isLoading: _isLoading('csv'),
            onTap: _exportFullSummaryCSV,
          ),
          const SizedBox(height: SSpacing.lg),

          // ── WhatsApp Section ─────────────────────────────────────────
          _SectionHeader('WhatsApp', Icons.chat, const Color(0xFF25D366)),
          const SizedBox(height: SSpacing.sm),
          _ExportCard(
            icon: Icons.payment_outlined,
            title: 'Send Payment Reminders',
            subtitle: '$pendingCount pending customers via WhatsApp',
            color: const Color(0xFF25D366),
            isLoading: _isLoading('wa_reminders'),
            onTap: _sendPaymentReminders,
            badge: pendingCount > 0 ? '$pendingCount' : null,
          ),
          _ExportCard(
            icon: Icons.inventory_outlined,
            title: 'Low Stock Alert',
            subtitle: lowStockCount > 0
                ? '$lowStockCount products need restocking'
                : 'All products well-stocked',
            color: lowStockCount > 0 ? SColors.warning : SColors.success,
            isLoading: _isLoading('wa_stock'),
            onTap: _sendLowStockAlert,
            badge: lowStockCount > 0 ? '$lowStockCount' : null,
          ),
          const SizedBox(height: SSpacing.xxl),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────
class _OverviewStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _OverviewStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: SColors.textOnDarkSub, size: 20),
      const SizedBox(height: SSpacing.xs),
      FittedBox(
        child: Text(value, style: SText.amountSm.copyWith(
            color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      Text(label, style: SText.labelXs.copyWith(color: SColors.textOnDarkSub)),
    ]),
  );
}

Widget _SectionHeader(String title, IconData icon, Color color) =>
    Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), borderRadius: SRadius.radiusSm),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    ]);

class _ExportCard extends StatelessWidget {
  final IconData     icon;
  final String       title, subtitle;
  final Color        color;
  final bool         isLoading;
  final VoidCallback onTap;
  final String?      badge;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SRadius.radiusMd,
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: SRadius.radiusMd),
            child: Icon(icon, color: color, size: 24),
          ),
          if (badge != null)
            Positioned(
              right: 0, top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: SColors.error, borderRadius: SRadius.radiusSm),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        )),
        isLoading
            ? SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(Icons.arrow_forward_ios, color: color, size: 16),
      ]),
    ),
  );
}
