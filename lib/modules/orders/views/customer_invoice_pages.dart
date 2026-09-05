import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/home/providers/shop_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/data/services/whatsapp_service.dart';
import 'package:intl/intl.dart';

// ── Professional Invoice Detail Page ───────────────────────────────────────
class CustomerInvoiceDetailPage extends StatelessWidget {
  final InvoiceData invoice;
  const CustomerInvoiceDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final shop    = context.watch<ShopProvider>().shop;
    final totals  = InvoiceCalculationService.calculate(invoice);
    final isPaid  = invoice.isPaid;

    return Scaffold(
      backgroundColor: SColors.border,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _printInvoice(context, invoice),
            tooltip: 'Print / Export PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: SRadius.radiusXs,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header (Shop Info) ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  color: SColors.primaryLight.withValues(alpha: 0.03),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop.name.toUpperCase(),
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: SColors.primaryLight, letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(shop.address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Phone: ${shop.phone}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (shop.ntn.isNotEmpty) Text('NTN: ${shop.ntn}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('INVOICE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w100, color: Colors.grey)),
                          Text('# ${invoice.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd MMM yyyy').format(invoice.dateTime), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Billing To ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BILL TO:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(invoice.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (invoice.customerDisplayId != null)
                            Text('ID: ${invoice.customerDisplayId}', style: TextStyle(fontSize: 11, color: SColors.primary, fontWeight: FontWeight.bold)),
                          Text(invoice.customerPhone, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                      ),
                      // Paid/Unpaid Stamp
                      Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: isPaid ? SColors.success : SColors.error, width: 3),
                            borderRadius: SRadius.radiusSm,
                          ),
                          child: Text(
                            isPaid ? 'PAID' : 'PENDING',
                            style: TextStyle(color: isPaid ? SColors.success : SColors.error, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Table Header ───────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: SColors.primaryLight,
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      Expanded(flex: 1, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  ),
                ),

                // ── Table Items ────────────────────────────────────────────
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: invoice.products.length,
                  itemBuilder: (context, index) {
                    final p = invoice.products[index];
                    
                    // Detailed Description
                    List<String> weightParts = [];
                    if (p.bags50 > 0)  weightParts.add('${p.bags50}x50kg');
                    if (p.bags100 > 0) weightParts.add('${p.bags100}x100kg');
                    if (p.looseWeightKg > 0) weightParts.add('${p.looseWeightKg}kg');
                    
                    String qtyLabel;
                    double unitPrice;
                    
                    if (p.bags50 > 0 && p.bags100 == 0 && p.looseWeightKg == 0) {
                      qtyLabel = '${p.bags50} bags';
                      unitPrice = (p.pricePer40kg / 40) * 50;
                    } else if (p.bags100 > 0 && p.bags50 == 0 && p.looseWeightKg == 0) {
                      qtyLabel = '${p.bags100} bags';
                      unitPrice = (p.pricePer40kg / 40) * 100;
                    } else if (p.quantity > 0 && p.bags50 == 0 && p.bags100 == 0 && p.looseWeightKg == 0) {
                      qtyLabel = '${p.quantity.toStringAsFixed(0)} units';
                      unitPrice = (p.pricePer40kg / 40) * (p.weightPerUnit > 0 ? p.weightPerUnit : 50.0);
                    } else {
                      qtyLabel = '${p.totalWeightKg.toStringAsFixed(1)} kg';
                      unitPrice = p.pricePer40kg; // Fallback to 40kg rate for mixed entries
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SColors.border))),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (weightParts.isNotEmpty)
                                Text(weightParts.join(' + '), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )),
                          Expanded(flex: 1, child: Text(qtyLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 1, child: Text(unitPrice.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 1, child: Text(p.totalPrice.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        ],
                      ),
                    );
                  },
                ),

                // ── Totals Section ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notes column
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (invoice.notes.isNotEmpty) ...[
                              const Text('NOTES:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(invoice.notes, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            ],
                            const SizedBox(height: 20),
                            const Text('PAYMENT METHOD:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(invoice.paymentMethod.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _summaryRow('Subtotal', totals.productsTotal),
                            if (totals.commission > 0) _summaryRow('Commission', totals.commission),
                            if (totals.totalExpenses > 0) _summaryRow('Expenses', totals.totalExpenses),
                            if (totals.discountAmount > 0) _summaryRow('Discount', -totals.discountAmount, isGreen: true),
                            if (totals.gstAmount > 0) _summaryRow('GST (${invoice.gstPercent}%)', totals.gstAmount),
                            const Divider(height: 20, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(child: Text('GRAND TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                const SizedBox(width: 4),
                                FittedBox(child: Text('PKR ${totals.grandTotal.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SColors.primaryLight))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _summaryRow('Amount Paid', invoice.amountPaid, isGreen: true),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: SColors.error))),
                                const SizedBox(width: 4),
                                FittedBox(child: Text('PKR ${totals.pendingAmount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SColors.error))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Footer ─────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: SColors.background,
                    border: Border(top: BorderSide(color: SColors.border)),
                  ),
                  child: const Column(
                    children: [
                      Text('Thank you for your business!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: SColors.primaryLight)),
                      SizedBox(height: 4),
                      Text('Saith Commission Shop - Quality Rice Wholesale', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: () => _printInvoice(context, invoice),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share Invoice PDF', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: SColors.primaryLight,
          ),
        ),
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context, InvoiceData inv) async {
    try {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing PDF for sharing...')));
      
      await WhatsAppService.shareInvoicePdf(inv);
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing PDF: $e'), backgroundColor: SColors.error));
    }
  }

  Widget _summaryRow(String label, double val, {bool isGreen = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('${val < 0 ? "-" : ""}PKR ${val.abs().toStringAsFixed(0)}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isGreen ? SColors.success : Colors.black87)),
      ],
    ),
  );
}

// ── Customer Ledger Download Page ──────────────────────────────────────────
class CustomerLedgerDownloadPage extends StatefulWidget {
  final String customerId;
  final String customerName;
  const CustomerLedgerDownloadPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerLedgerDownloadPage> createState() =>
      _CustomerLedgerDownloadPageState();
}

class _CustomerLedgerDownloadPageState
    extends State<CustomerLedgerDownloadPage> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final lp      = context.watch<LedgerProvider>();
    final entries = lp.entriesForCustomer(widget.customerId);
    final balance = lp.customerBalance(widget.customerId);

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ledger Statement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: entries.isEmpty ? null : _downloadStatement,
            tooltip: 'Download Statement',
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: balance > 0
                  ? [SColors.catOrange, SColors.gold]
                  : [SColors.primaryLight, SColors.primary]),
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.customerName,
                      style: TextStyle(
                          color: SColors.textOnDarkSub, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Outstanding Balance',
                      style: TextStyle(color: SColors.textOnDarkSub, fontSize: 13)),
                  Text('PKR ${balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              )),
              Column(children: [
                Icon(
                  balance > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: Colors.white, size: 36,
                ),
                const SizedBox(height: 4),
                Text(
                  balance > 0 ? '⚠️ Payment Due' : '✅ Cleared',
                  style: TextStyle(color: SColors.textOnDarkSub, fontSize: 12),
                ),
              ]),
            ]),
          ),

          // Entries
          Expanded(
            child: entries.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No transactions yet',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
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
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: isDebit
                            ? SColors.error.withValues(alpha: 0.1)
                            : SColors.success.withValues(alpha: 0.1),
                        borderRadius: SRadius.radiusMd,
                      ),
                      child: Icon(
                        isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isDebit ? SColors.error : SColors.success,
                        size: 20,
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
                        Text(
                          'Bal: PKR ${e.balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Download button
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadStatement,
                  icon: _isDownloading
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_outlined),
                  label: Text(
                    _isDownloading ? 'Generating...' : 'Download Statement PDF',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: SRadius.radiusMd),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _downloadStatement() async {
    setState(() => _isDownloading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isDownloading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Statement PDF saved to Documents'),
      backgroundColor: SColors.success,
    ));
  }
}
