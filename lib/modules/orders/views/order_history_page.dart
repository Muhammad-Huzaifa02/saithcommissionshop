import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});
  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _filter = 'all'; // all | paid | pending
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final ip       = context.watch<InvoiceProvider>();
    final customer = context.watch<CustomerProvider>().currentCustomer;

    // Show only this customer's orders if logged in as customer
    final allInvoices = customer != null
        ? ip.invoicesByCustomer(customer.id)
        : ip.invoices;

    final invoices = allInvoices.where((inv) {
      final matchFilter = _filter == 'all' ||
          (_filter == 'paid'    &&  inv.isPaid) ||
          (_filter == 'pending' && !inv.isPaid);
      final matchSearch = _search.isEmpty ||
          inv.invoiceNo.toLowerCase().contains(_search.toLowerCase()) ||
          inv.customerName.toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    final totalSpent  = allInvoices.fold(0.0, (s, i) => s + i.grandTotal);
    final totalPending = allInvoices.where((i) => !i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Order History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () async {
              final dir = await getApplicationDocumentsDirectory();
              if (!mounted || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Orders saved in: ${dir.path}'),
                  backgroundColor: AppTheme.darkGreen,
                ),
              );
            },
            tooltip: 'Storage Path',
          ),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: SRadius.radiusSm),
              child: const Icon(Icons.filter_list, size: 20),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all',     child: Text('All Orders')),
              PopupMenuItem(value: 'paid',    child: Text('Paid')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats strip
          Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _Stat('Total Orders', '${allInvoices.length}', Colors.white)),
                Expanded(child: _Stat('Total Spent', 'PKR ${_fmt(totalSpent)}', Colors.greenAccent)),
                Expanded(child: _Stat('Due', 'PKR ${_fmt(totalPending)}',
                    totalPending > 0 ? Colors.orangeAccent : Colors.greenAccent)),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _search = ''),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: SRadius.radiusMd,
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // List
          Expanded(
            child: invoices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: SColors.textTertiary),
                  const SizedBox(height: 12),
                  const Text('No orders yet',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/customer-home', (_) => false),
                    icon: const Icon(Icons.store_outlined),
                    label: const Text('Start Shopping'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: invoices.length,
              itemBuilder: (_, i) =>
                  _OrderCard(invoice: invoices[i]),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

class _OrderCard extends StatelessWidget {
  final InvoiceData invoice;
  const _OrderCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SRadius.radiusLg,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(inv.invoiceNo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (inv.customerDisplayId != null)
                        Text(inv.customerDisplayId!,
                            style: const TextStyle(fontSize: 10, color: AppTheme.green, fontWeight: FontWeight.bold)),
                      Text(
                        '${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: inv.isPaid
                        ? SColors.success.withValues(alpha: 0.1)
                        : SColors.warning.withValues(alpha: 0.1),
                    borderRadius: SRadius.radiusLg,
                  ),
                  child: Text(
                    inv.isPaid ? 'Paid' : 'Pending',
                    style: TextStyle(
                        fontSize: 12,
                        color: inv.isPaid ? SColors.success : SColors.warning,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Products
            ...inv.products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(p.name,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.quantity.toStringAsFixed(0)} bags × PKR ${p.pricePer40kg.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )),
            const Divider(height: 16),

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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.green),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!inv.isPaid)
                        Text(
                          'Due: PKR ${(inv.grandTotal - inv.amountPaid).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: SColors.warning),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _downloadPdf(context, inv),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('PDF'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.green,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context, InvoiceData inv) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 1)));
      final file = await PdfInvoiceService.generate(inv);
      
      // Use dart:io to check file existence and size
      final fileObj = File(file.path);
      if (await fileObj.exists()) {
        final bytes = await fileObj.length();
        final kb = (bytes / 1024).toStringAsFixed(1);
        
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(
          content: Text('Saved: ${file.path.split(Platform.pathSeparator).last} ($kb KB)'),
          backgroundColor: SColors.success,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: SColors.error,
      ));
    }
  }
}

