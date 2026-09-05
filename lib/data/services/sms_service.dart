import 'package:url_launcher/url_launcher.dart';
import 'package:saithcommissionshop/core/utils/utils.dart';

class SmsService {
  /// Open SMS app pre-filled with message.
  static Future<void> sendSms({
    required String phone,
    required String message,
  }) async {
    final normalized = PakistanFormatter.normalizePhone(phone);
    final uri = Uri.parse('sms:$normalized?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ── ENGLISH TEMPLATES ────────────────────────────────────────────────────────
  static Future<void> sendPaymentReminder({
    required String phone,
    required String customerName,
    required double pendingAmount,
    required String invoiceNo,
  }) async {
    final msg = '''Dear $customerName,
Your invoice #$invoiceNo has a pending balance of PKR ${pendingAmount.toStringAsFixed(0)}.
Please clear the payment.
Saith Commission Shop''';
    await sendSms(phone: phone, message: msg);
  }

  static Future<void> sendInvoiceNotification({
    required String phone,
    required String customerName,
    required String invoiceNo,
    required double total,
  }) async {
    final msg = '''Dear $customerName,
Your invoice #$invoiceNo is ready.
Total Amount: PKR ${total.toStringAsFixed(0)}
Saith Commission Shop''';
    await sendSms(phone: phone, message: msg);
  }

  static Future<void> sendWelcome({
    required String phone,
    required String customerName,
  }) async {
    final msg =
        'Welcome $customerName to Saith Commission Shop! 🌾';
    await sendSms(phone: phone, message: msg);
  }

  static Future<void> sendPaymentConfirmation({
    required String phone,
    required String customerName,
    required double amount,
  }) async {
    final msg =
    '''Dear $customerName,
Payment of PKR ${amount.toStringAsFixed(0)} has been received. Thank you! 🙏
Saith Commission Shop''';
    await sendSms(phone: phone, message: msg);
  }
}
