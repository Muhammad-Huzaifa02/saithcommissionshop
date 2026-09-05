import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';
import 'package:saithcommissionshop/modules/orders/views/customer_invoice_pages.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});
  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  String _search = '';
  String _filter = 'all'; // all | paid | pending

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();

    final filtered = ip.invoices.where((inv) {
      final matchFilter = _filter == 'all' ||
          (_filter == 'paid'    &&  inv.isPaid) ||
          (_filter == 'pending' && !inv.isPaid);
      final matchSearch = _search.isEmpty ||
          inv.customerName.toLowerCase().contains(_search.toLowerCase()) ||
          inv.invoiceNo.contains(_search) ||
          inv.customerPhone.contains(_search);
      return matchFilter && matchSearch;
    }).toList();

    final totalAmt   = filtered.fold(0.0, (s, i) => s + i.grandTotal);
    final paidAmt    = filtered.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);
    final pendingAmt = filtered.where((i) => !i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);

    return AppPageScaffold(
      title: 'Invoices (${ip.invoices.length})',
      actions: [
        IconButton(
          icon: const Icon(Icons.folder_open_outlined),
          onPressed: () async {
            final dir = await getApplicationDocumentsDirectory();
            if (!mounted || !context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invoices stored in: ${dir.path}'),
                backgroundColor: AppTheme.darkGreen,
              ),
            );
          },
          tooltip: 'View Storage Path',
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => Navigator.pushNamed(context, '/admin-invoice'),
          tooltip: 'New Invoice',
        ),
      ],
      body: Column(
        children: [
          // ── Summary strip ──────────────────────────────────────
          Container(
            color: AppTheme.darkGreen,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryChip('Total',   'PKR ${_fmt(totalAmt)}',   Colors.white),
                _SummaryChip('Paid',    'PKR ${_fmt(paidAmt)}',    Colors.greenAccent),
                _SummaryChip('Pending', 'PKR ${_fmt(pendingAmt)}', Colors.orangeAccent),
              ],
            ),
          ),

          // ── Search + filter ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or invoice no...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _search = ''),
                    )
                        : null,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: SRadius.radiusMd,
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _filter = v),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: SRadius.radiusMd),
                  child: Icon(Icons.filter_list,
                      color: _filter == 'all'
                          ? Colors.grey
                          : AppTheme.green),
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'all',     child: Text('All')),
                  PopupMenuItem(value: 'paid',    child: Text('Paid')),
                  PopupMenuItem(value: 'pending', child: Text('Pending')),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 8),

          // ── Results count ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${filtered.length} result${filtered.length != 1 ? "s" : ""}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (_filter != 'all')
                  GestureDetector(
                    onTap: () => setState(() { _filter = 'all'; _search = ''; }),
                    child: const Text('Clear filter',
                        style: TextStyle(color: AppTheme.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── List ──────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: SColors.textTertiary),
                  const SizedBox(height: 12),
                  const Text('No invoices found',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: filtered.length,
              itemBuilder: (_, i) =>
                  _InvoiceCard(invoice: filtered[i]),
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

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label,
        style: const TextStyle(color: Colors.white60, fontSize: 11)),
  ]);
}

// ── Individual invoice card ───────────────────────────────────────────────
class _InvoiceCard extends StatelessWidget {
  final InvoiceData invoice;
  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final inv = invoice;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SRadius.radiusMd,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerInvoiceDetailPage(invoice: inv),
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: inv.isPaid
                ? SColors.success.withValues(alpha: 0.1)
                : SColors.warning.withValues(alpha: 0.1),
            borderRadius: SRadius.radiusMd,
          ),
          child: Icon(
            inv.isPaid
                ? Icons.check_circle_outline
                : Icons.pending_outlined,
            color: inv.isPaid ? SColors.success : SColors.warning,
          ),
        ),
        title: Row(children: [
          Expanded(
            child: ResponsiveText(inv.customerName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: inv.isPaid
                  ? SColors.success.withValues(alpha: 0.1)
                  : SColors.warning.withValues(alpha: 0.1),
              borderRadius: SRadius.radiusSm,
            ),
            child: Text(inv.isPaid ? 'Paid' : 'Pending',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: inv.isPaid ? SColors.success : SColors.warning)),
          ),
        ]),
        subtitle: Text(
          '${inv.customerDisplayId ?? "GUEST"}  ·  ${inv.invoiceNo}  ·  ${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year}  ·  ${inv.paymentMethod}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${inv.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  inv.paymentMethod.toUpperCase(),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            _QuickPdfButton(invoice: inv),
          ],
        ),
      ),
    );
  }
}

// ── Quick PDF Action ──────────────────────────────────────────────────────
class _QuickPdfButton extends StatefulWidget {
  final InvoiceData invoice;
  const _QuickPdfButton({required this.invoice});

  @override
  State<_QuickPdfButton> createState() => _QuickPdfButtonState();
}

class _QuickPdfButtonState extends State<_QuickPdfButton> {
  bool _isGenerating = false;

  Future<void> _handlePdf() async {
    setState(() => _isGenerating = true);
    try {
      final file = await PdfInvoiceService.generate(widget.invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Invoice saved to ${file.path.split(Platform.pathSeparator).last}'),
          backgroundColor: SColors.success,
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () {
              // Open logic can be added here
            },
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: SColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isGenerating
        ? const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.green))
        : IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent, size: 22),
            onPressed: _handlePdf,
            tooltip: 'Download PDF',
          );
  }
}
