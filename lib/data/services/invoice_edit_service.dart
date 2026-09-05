import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/invoice_correction_model.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class InvoiceEditService {
  // NOTE: in-memory only — this history resets on app restart and doesn't
  // sync across devices/admins. Fine for a "just happened" undo-style view
  // within a session; not a substitute for a real audit log if you need one
  // that persists (the stock_history entries this writes DO persist,
  // they just aren't grouped as a single correction record anywhere yet).
  static final List<InvoiceCorrection> _corrections = [];

  static List<InvoiceCorrection> get corrections =>
      List.unmodifiable(_corrections);

  /// Builds the net stock change per product for going from [original] to
  /// [updated]: restoring every original line and deducting every updated
  /// line, combined into one delta per product (so a product appearing in
  /// both only needs one write, and stock-sufficiency is validated against
  /// the real net effect, not two independent steps that could each pass
  /// individually while the combination doesn't).
  static Map<String, double> _netStockDeltas(InvoiceData original, InvoiceData updated) {
    final deltas = <String, double>{};
    for (final item in original.products) {
      if (item.productId == null || item.productId!.isEmpty) continue;
      deltas[item.productId!] = (deltas[item.productId!] ?? 0) + item.totalWeightKg;
    }
    for (final item in updated.products) {
      if (item.productId == null || item.productId!.isEmpty) continue;
      deltas[item.productId!] = (deltas[item.productId!] ?? 0) - item.totalWeightKg;
    }
    return deltas;
  }

  /// Replace an existing invoice with updated data.
  static Future<void> editInvoice({
    required InvoiceProvider invoiceProvider,
    required InvoiceData original,
    required InvoiceData updated,
    required String reason,
    required String editedBy,
  }) async {
    final oldTotal = InvoiceCalculationService.calculate(original).grandTotal;
    final newTotal = InvoiceCalculationService.calculate(updated).grandTotal;

    // Atomic: every affected product's stock is read fresh, validated, and
    // written together — rejects the whole edit rather than guessing by
    // touching an arbitrary unrelated product if something can't be matched.
    await FirebaseService.applyStockDeltas(
      deltaByProductId: _netStockDeltas(original, updated),
      reference: 'EDIT-${original.invoiceNo}',
      adminId: editedBy,
      notes: 'Stock adjusted via invoice edit: $reason',
    );

    // Update invoice in provider
    await invoiceProvider.updateInvoice(original.invoiceNo, updated);

    // Log correction
    _corrections.insert(
      0,
      InvoiceCorrection(
        invoiceNo: original.invoiceNo,
        correctedAt: DateTime.now(),
        reason: reason,
        oldTotal: oldTotal,
        newTotal: newTotal,
        correctedBy: editedBy,
      ),
    );
  }

  /// Void an invoice entirely.
  static Future<void> voidInvoice({
    required InvoiceProvider invoiceProvider,
    required InvoiceData invoice,
    required String reason,
    required String voidedBy,
  }) async {
    // Restore stock for every line with a resolvable product — atomic and
    // validated, same as editInvoice.
    final restoreDeltas = <String, double>{};
    for (final item in invoice.products) {
      if (item.productId == null || item.productId!.isEmpty) continue;
      restoreDeltas[item.productId!] = (restoreDeltas[item.productId!] ?? 0) + item.totalWeightKg;
    }
    await FirebaseService.applyStockDeltas(
      deltaByProductId: restoreDeltas,
      reference: 'VOID-${invoice.invoiceNo}',
      adminId: voidedBy,
      notes: 'Stock restored via invoice void: $reason',
    );

    await invoiceProvider.deleteInvoice(invoice.invoiceNo);

    _corrections.insert(
      0,
      InvoiceCorrection(
        invoiceNo: invoice.invoiceNo,
        correctedAt: DateTime.now(),
        reason: 'VOID: $reason',
        oldTotal: InvoiceCalculationService.calculate(invoice).grandTotal,
        newTotal: 0,
        correctedBy: voidedBy,
      ),
    );
  }
}
