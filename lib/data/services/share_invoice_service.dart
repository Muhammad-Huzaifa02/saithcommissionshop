import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';

class ShareInvoiceService {
  /// Share PDF via any app (WhatsApp, email, etc.)
  static Future<void> sharePdf(InvoiceData invoice) async {
    final file = await PdfInvoiceService.generate(invoice);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice ${invoice.invoiceNo} - Saith Commission Shop\n'
          'Amount: PKR ${invoice.grandTotal.toStringAsFixed(0)}\n'
          'Customer: ${invoice.customerName}',
      subject: 'Invoice ${invoice.invoiceNo}',
    );
  }

  /// Send invoice text via WhatsApp
  static Future<void> sendWhatsApp(InvoiceData invoice) async {
    final phone = invoice.customerPhone
        .replaceAll(RegExp(r'[^0-9]'), '')
        .replaceFirst(RegExp(r'^0'), '92');

    final msg = Uri.encodeComponent(
      '🧾 *Invoice: ${invoice.invoiceNo}*\n'
          '━━━━━━━━━━━━━━━━━━\n'
          '👤 Customer: ${invoice.customerName}\n'
          '📅 Date: ${invoice.dateTime.day}/${invoice.dateTime.month}/${invoice.dateTime.year}\n\n'
          '*Items:*\n'
          '${invoice.products.map((p) => '• ${p.name}: ${p.quantity.toStringAsFixed(0)} bags × PKR ${p.pricePer40kg.toStringAsFixed(0)} = PKR ${p.totalPrice.toStringAsFixed(0)}').join('\n')}\n\n'
          '━━━━━━━━━━━━━━━━━━\n'
          '💰 *Total: PKR ${invoice.grandTotal.toStringAsFixed(0)}*\n'
          '${invoice.gstRate > 0 ? '🏛️ GST (${(invoice.gstRate * 100).toStringAsFixed(0)}%): PKR ${invoice.gstAmount.toStringAsFixed(0)}\n' : ''}'
          '✅ Status: ${invoice.isPaid ? 'PAID' : 'PENDING'}\n\n'
          '_Saith Commission Shop • Lahore, Pakistan 🇵🇰_',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Quick text summary for copying
  static String buildTextSummary(InvoiceData invoice) {
    return '''
Invoice: ${invoice.invoiceNo}
Customer: ${invoice.customerName}
Date: ${invoice.dateTime.day}/${invoice.dateTime.month}/${invoice.dateTime.year}

${invoice.products.map((p) => '${p.name}: ${p.quantity.toStringAsFixed(0)} bags @ PKR ${p.pricePer40kg.toStringAsFixed(0)} = PKR ${p.totalPrice.toStringAsFixed(0)}').join('\n')}

Subtotal: PKR ${invoice.subtotal.toStringAsFixed(0)}
${invoice.gstRate > 0 ? 'GST (${(invoice.gstRate * 100).toStringAsFixed(0)}%): PKR ${invoice.gstAmount.toStringAsFixed(0)}\n' : ''}Grand Total: PKR ${invoice.grandTotal.toStringAsFixed(0)}
Status: ${invoice.isPaid ? 'PAID' : 'PENDING'}

Saith Commission Shop • Lahore, Pakistan
''';
  }
}
