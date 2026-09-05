import 'dart:async';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/data/services/payment_reminder_service.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class ReminderSchedulerService {
  static Timer? _timer;
  static bool _isRunning = false;

  /// Start the scheduler. Fires every [intervalHours] hours.
  static void start(InvoiceProvider provider, {int intervalHours = 24}) {
    if (_isRunning) {
      return;
    }
    _isRunning = true;

    _timer = Timer.periodic(Duration(hours: intervalHours), (_) async {
      await _sendDueReminders(provider);
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  static bool get isRunning => _isRunning;

  static Future<void> runNow(InvoiceProvider provider) async {
    await _sendDueReminders(provider);
  }

  static Future<void> _sendDueReminders(InvoiceProvider provider) async {
    final overdue = provider.invoices.where((inv) {
      final pending = InvoiceCalculationService.calculate(inv).pendingAmount;
      if (pending <= 0) return false;
      final daysSince = DateTime.now().difference(inv.dateTime).inDays;
      return daysSince >= 3;
    }).toList();

    await PaymentReminderService.sendBulkReminders(invoices: overdue);
  }
}
