import 'dart:io';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/data/services/whatsapp_invoice_service.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';

class AutoPaymentReminderService {
  /// Sends WhatsApp reminders for every invoice that has a pending amount.
  static Future<void> sendReminders(InvoiceProvider provider) async {
    for (final invoice in provider.invoices) {
      final pending =
          InvoiceCalculationService.calculate(invoice).pendingAmount;
      if (pending > 0) {
        final File pdfFile = await PdfInvoiceService.generate(invoice);
        await WhatsAppInvoiceService.sendInvoice(
          phone: invoice.customerPhone,
          pdfFile: pdfFile,
        );
      }
    }
  }
}
