import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/core/utils/utils.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class WhatsAppInvoiceService {
  /// Share PDF via WhatsApp (uses system share → user picks WhatsApp).
  static Future<void> sendInvoice({
    required String phone,
    required File pdfFile,
  }) async {
    final xFile = XFile(pdfFile.path, mimeType: 'application/pdf');
    await Share.shareXFiles([xFile]);
  }

  /// Open WhatsApp chat with pre-filled text message.
  static Future<void> sendTextMessage({
    required String phone,
    required String message,
  }) async {
    final normalized = PakistanFormatter.normalizePhone(phone).replaceAll('+', '');
    final url = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Send invoice summary as WhatsApp text.
  static Future<void> sendInvoiceSummary(InvoiceData invoice) async {
    final calc = InvoiceCalculationService.calculate(invoice);
    final products = invoice.products
        .map((p) => '• ${p.name} x${p.quantity} = PKR ${p.totalAmount.toStringAsFixed(0)}')
        .join('\n');

    final message = '''🏪 *Saith Commission Shop*
Invoice #: ${invoice.invoiceNo}
Customer: ${invoice.customerName}
Date: ${PakistanFormatter.formatDate(invoice.dateTime)}

$products

Total: *PKR ${calc.grandTotal.toStringAsFixed(0)}*
Paid: PKR ${invoice.amountPaid.toStringAsFixed(0)}
Pending: *PKR ${calc.pendingAmount.toStringAsFixed(0)}*

Thank you 🙏''';

    await sendTextMessage(phone: invoice.customerPhone, message: message);
  }

  /// Send payment reminder via WhatsApp.
  static Future<void> sendPaymentReminder({
    required String phone,
    required String customerName,
    required double pendingAmount,
    required String invoiceNo,
  }) async {
    final message =
        'Dear *$customerName*,\n'
        'Your invoice #$invoiceNo has a '
        'pending balance of *PKR ${pendingAmount.toStringAsFixed(0)}*.\n'
        'Please clear the payment at your earliest convenience.\n'
        'Saith Commission Shop 🌾';
    await sendTextMessage(phone: phone, message: message);
  }

  /// Generate PDF and share via WhatsApp.
  static Future<void> generateAndSend(InvoiceData invoice) async {
    final file = await PdfInvoiceService.generate(invoice);
    await sendInvoice(phone: invoice.customerPhone, pdfFile: file);
  }
}
