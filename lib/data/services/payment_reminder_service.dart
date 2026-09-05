import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/sms_service.dart';
import 'package:saithcommissionshop/data/services/whatsapp_invoice_service.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

enum ReminderType { sms, whatsapp, both }

class PaymentReminderService {
  static Future<void> sendReminder({
    required InvoiceData invoice,
    ReminderType type = ReminderType.whatsapp,
  }) async {
    final pending =
        InvoiceCalculationService.calculate(invoice).pendingAmount;
    if (pending <= 0) {
      return;
    }

    if (type == ReminderType.sms || type == ReminderType.both) {
      await SmsService.sendPaymentReminder(
        phone: invoice.customerPhone,
        customerName: invoice.customerName,
        pendingAmount: pending,
        invoiceNo: invoice.invoiceNo,
      );
    }

    if (type == ReminderType.whatsapp || type == ReminderType.both) {
      await WhatsAppInvoiceService.sendPaymentReminder(
        phone: invoice.customerPhone,
        customerName: invoice.customerName,
        pendingAmount: pending,
        invoiceNo: invoice.invoiceNo,
      );
    }
  }

  static Future<void> sendBulkReminders({
    required List<InvoiceData> invoices,
    ReminderType type = ReminderType.whatsapp,
  }) async {
    for (final invoice in invoices) {
      await sendReminder(invoice: invoice, type: type);
    }
  }
}
