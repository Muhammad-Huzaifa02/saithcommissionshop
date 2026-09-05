import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/data/models/ledger_entry.dart';
import 'package:saithcommissionshop/data/services/ledger_pdf_service.dart';
import 'package:saithcommissionshop/data/services/whatsapp_service.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';


class CustomerLedgerPage extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerLedgerPage({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerLedgerPage> createState() => _CustomerLedgerPageState();
}

class _CustomerLedgerPageState extends State<CustomerLedgerPage> {
  bool _downloadingPdf = false;
  bool _sendingWa      = false;

  @override
  void dispose() {
    // Note: context.read is unsafe in dispose.
    // Provider unsubscriptions for streams happen automatically if the provider is disposed,
    // but if we need manual cleanup, we should use a safer pattern.
    // For now, we'll remove this as it causes a crash and the stream 
    // is usually managed by the provider's lifecycle.
    super.dispose();
  }

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_startDate == null || _endDate == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Date Range'),
          content: const Text('Please select a date range for the ledger statement.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Select Date')),
          ],
        ),
      );
      if (confirm == true) {
        await _selectDateRange();
        if (_startDate == null || _endDate == null) return;
      } else {
        return;
      }
    }

    setState(() => _downloadingPdf = true);
    try {
      final lp       = context.read<LedgerProvider>();
      final allEntries  = lp.entriesForCustomer(widget.customerId);
      
      final filteredEntries = allEntries.where((e) {
        return e.dateTime.isAfter(_startDate!) && 
               e.dateTime.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      if (filteredEntries.isEmpty) {
        _snack('No transactions found in selected range', SColors.warning);
        return;
      }

      await LedgerPdfService.shareStatement(
        customerId:    widget.customerId,
        customerName:  widget.customerName,
        customerPhone: '',
        entries:       filteredEntries,
      );
      if (!mounted || !context.mounted) return;
      _snack('Statement ready to share ✓', SColors.success);
    } catch (e) {
      if (!mounted || !context.mounted) return;
      _snack('Failed to generate PDF: $e', SColors.error);
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  Future<void> _sendWhatsApp() async {
    setState(() => _sendingWa = true);
    try {
      final lp      = context.read<LedgerProvider>();
      final entries = lp.entriesForCustomer(widget.customerId);
      final balance = lp.customerBalance(widget.customerId);
      final phone   = _getPhone(entries);

      if (phone.isEmpty) {
        if (!mounted) return;
        _snack('No phone number available', SColors.warning);
        return;
      }

      final ok = await WhatsAppService.sendPaymentReminder(
        customerName:  widget.customerName,
        customerPhone: phone,
        pendingAmount: balance,
        shopName:      'Saith Commission Shop',
      );
      if (!mounted) return;
      if (!ok) _snack('WhatsApp not available on this device', SColors.warning);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', SColors.error);
    } finally {
      if (mounted) setState(() => _sendingWa = false);
    }
  }


  String _getPhone(List<LedgerEntry> entries) {
    // Phone can be extracted from invoice if integrated; use empty for now
    return '';
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color,
            behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final ledger  = context.watch<LedgerProvider>();
    final allEntries = ledger.entriesForCustomer(widget.customerId);
    final balance = ledger.customerBalance(widget.customerId);
    
    final entries = _startDate == null ? allEntries : allEntries.where((e) {
      return e.dateTime.isAfter(_startDate!) && 
             e.dateTime.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();

    final customer = context.read<CustomerProvider>().getCustomerById(widget.customerId);
    final displayId = customer?.customerId ?? 'N/A';

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Ledger Statement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: SRadius.radiusXs),
                  child: Text(displayId, 
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
            Text(widget.customerName,
                style: TextStyle(fontSize: 12, color: SColors.textOnDarkSub)),
          ],
        ),
        actions: [
          // WhatsApp reminder
          if (balance > 0)
            _sendingWa
                ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: _sendWhatsApp,
              tooltip: 'Send WhatsApp Reminder',
            ),
          // Download PDF
          _downloadingPdf
              ? const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: entries.isEmpty ? null : _downloadPdf,
            tooltip: 'Download PDF Statement',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Balance Banner ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: balance > 0
                    ? [SColors.catOrange, SColors.gold]
                    : [SColors.primaryLight, SColors.primary],
              ),
            ),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Outstanding Balance',
                          style: TextStyle(color: SColors.textOnDarkSub, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(PakistanFormatter.formatPKRWithCommas(balance),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        balance > 0 ? '⚠️ Payment due' : '✅ Account cleared',
                        style: TextStyle(color: SColors.textOnDarkSub, fontSize: 12),
                      ),
                    ],
                  )),
                  Column(children: [
                    Icon(
                      balance > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
                      color: Colors.white, size: 40,
                    ),
                    if (entries.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('${entries.length} entries',
                          style: TextStyle(color: SColors.textOnDarkSub, fontSize: 11)),
                    ],
                  ]),
                ]),
                if (entries.isNotEmpty) ...[
                  const Divider(color: Colors.white30, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startDate == null ? 'Showing All Transactions' : 'Range: ${PakistanFormatter.formatDate(_startDate!)} - ${PakistanFormatter.formatDate(_endDate!)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range, color: Colors.white, size: 16),
                        label: const Text('Filter Date', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: TextButton.styleFrom(backgroundColor: Colors.white10),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Action Buttons ─────────────────────────────────────
          if (entries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _downloadingPdf ? null : _downloadPdf,
                    icon: _downloadingPdf
                        ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Download PDF'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: SColors.error,
                        side: BorderSide(color: SColors.error)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendingWa ? null : _sendWhatsApp,
                    icon: _sendingWa
                        ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white),
                  ),
                ),
              ]),
            ),

          // ── Summary Stats ──────────────────────────────────────
          if (entries.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                _SumStat('Total Debit',
                    Fmt.currency(entries.fold(0.0, (s, e) => s + e.debit)),
                    SColors.error),
                const SizedBox(width: 8),
                _SumStat('Total Credit',
                    Fmt.currency(entries.fold(0.0, (s, e) => s + e.credit)),
                    SColors.success),
                const SizedBox(width: 8),
                _SumStat('Transactions', '${entries.length}', SColors.catBlue),
              ]),
            ),

          // ── Entries List ───────────────────────────────────────
          Expanded(
            child: entries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: SColors.textTertiary),
                  const SizedBox(height: 12),
                  const Text('No transactions yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e       = entries[i];
                final isDebit = e.debit > 0;
                return Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: SRadius.radiusMd,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
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
                        '${PakistanFormatter.formatDate(e.dateTime)}  ·  '
                            '${_typeName(e.type)}',
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _typeName(LedgerType type) {
    switch (type) {
      case LedgerType.invoice:    return 'Invoice';
      case LedgerType.payment:    return 'Payment';
      case LedgerType.adjustment: return 'Adjustment';
    }
  }
}

class _SumStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _SumStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: SRadius.radiusSm),
      child: Column(children: [
        Text(value, style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
      ]),
    ),
  );
}
