import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/ledger_entry.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';
import 'package:saithcommissionshop/data/services/ledger_pdf_service.dart';

class WhatsAppService {
  // ── Send Invoice via WhatsApp ──────────────────────────────────────────────
  static Future<bool> sendInvoice(InvoiceData invoice) async {
    final msg = _buildInvoiceMessage(invoice);
    return _openWhatsApp(invoice.customerPhone, msg);
  }

  // ── Send Payment Reminder ──────────────────────────────────────────────────
  static Future<bool> sendPaymentReminder({
    required String customerName,
    required String customerPhone,
    required double pendingAmount,
    required String shopName,
  }) async {
    final msg =
        '🔔 *Payment Reminder*\n\n'
        'Dear *$customerName*,\n\n'
        'This is a gentle reminder that you have an outstanding balance of:\n\n'
        '💰 *PKR ${PakistanFormatter.formatPKRWithCommas(pendingAmount)}*\n\n'
        'Please settle your account at your earliest convenience.\n\n'
        'Thank you for your business! 🙏\n\n'
        '━━━━━━━━━━━━━━━━━━\n'
        '_$shopName • Lahore, Pakistan 🇵🇰_';

    return _openWhatsApp(customerPhone, msg);
  }

  // ── Send Low Stock Alert to Admin ──────────────────────────────────────────
  static Future<bool> sendLowStockAlert({
    required String adminPhone,
    required List<Map<String, dynamic>> lowStockItems,
    required String shopName,
  }) async {
    final itemLines = lowStockItems
        .map((i) => '• ${i['name']}: ${i['stock']} kg remaining')
        .join('\n');

    final msg =
        '⚠️ *Low Stock Alert — $shopName*\n\n'
        'The following products need restocking:\n\n'
        '$itemLines\n\n'
        '📅 Date: ${PakistanFormatter.formatDate(DateTime.now())}\n\n'
        '_Please restock soon to avoid out-of-stock issues._';

    return _openWhatsApp(adminPhone, msg);
  }

  // ── Share Invoice PDF via WhatsApp ─────────────────────────────────────────
  static Future<void> shareInvoicePdf(InvoiceData invoice) async {
    try {
      final file = await PdfInvoiceService.generate(invoice);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ${invoice.invoiceNo}',
        text: _buildInvoiceMessage(invoice),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── Share Ledger PDF via WhatsApp ──────────────────────────────────────────
  static Future<void> shareLedgerPdf({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required List<LedgerEntry> entries,
  }) async {
    await LedgerPdfService.shareStatement(
      customerId:    customerId,
      customerName:  customerName,
      customerPhone: customerPhone,
      entries:       entries,
    );
  }

  // ── Copy message to clipboard ──────────────────────────────────────────────
  static Future<void> copyInvoiceToClipboard(InvoiceData invoice) async {
    final msg = _buildInvoiceMessage(invoice);
    await Clipboard.setData(ClipboardData(text: msg));
  }

  // ── Internal helpers ───────────────────────────────────────────────────────
  static Future<bool> _openWhatsApp(String phone, String message) async {
    final normalized = PakistanFormatter.normalizePhone(phone)
        .replaceAll('+', '');
    final encoded = Uri.encodeComponent(message);

    // Try WhatsApp direct first
    final waUrl = Uri.parse('whatsapp://send?phone=$normalized&text=$encoded');
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      return true;
    }

    // Fallback: wa.me web link
    final webUrl = Uri.parse('https://wa.me/$normalized?text=$encoded');
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      return true;
    }

    return false;
  }

  static String _buildInvoiceMessage(InvoiceData invoice) {
    final itemLines = invoice.products
        .map((p) =>
    '  • ${p.name}: ${p.quantity.toStringAsFixed(0)} bags '
        '× PKR ${p.pricePer40kg.toStringAsFixed(0)} '
        '= PKR ${p.totalPrice.toStringAsFixed(0)}')
        .join('\n');

    final pending = invoice.grandTotal - invoice.amountPaid;

    return '🧾 *INVOICE — ${invoice.invoiceNo}*\n'
        '━━━━━━━━━━━━━━━━━━━━\n'
        '👤 *${invoice.customerName}*\n'
        '📞 ${invoice.customerPhone}\n'
        '📅 ${PakistanFormatter.formatDate(invoice.dateTime)}\n\n'
        '*Items:*\n$itemLines\n\n'
        '━━━━━━━━━━━━━━━━━━━━\n'
        '${invoice.gstPercent > 0 ? '🏛 GST (${invoice.gstPercent.toStringAsFixed(0)}%): PKR ${(invoice.grandTotal * invoice.gstPercent / 100).toStringAsFixed(0)}\n' : ''}'
        '💰 *Total: PKR ${invoice.grandTotal.toStringAsFixed(0)}*\n'
        '${invoice.amountPaid > 0 ? '✅ Paid: PKR ${invoice.amountPaid.toStringAsFixed(0)}\n' : ''}'
        '${pending > 0 ? '⚠️ Balance Due: PKR ${pending.toStringAsFixed(0)}\n' : ''}'
        '🏷 Status: *${invoice.isPaid ? 'PAID ✅' : 'PENDING ⏳'}*\n'
        '💳 Method: ${invoice.paymentMethod.toUpperCase()}\n\n'
        '━━━━━━━━━━━━━━━━━━━━\n'
        '_Saith Commission Shop_\n'
        '_Lahore, Pakistan 🇵🇰_';
  }
}
