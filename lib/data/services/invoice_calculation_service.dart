import 'package:saithcommissionshop/data/models/invoice_models.dart';

class InvoiceTotals {
  final double productsTotal;
  final double commission;
  final double totalExpenses;
  final double subTotal;
  final double discountAmount;
  final double gstAmount;
  final double grandTotal;
  final double pendingAmount;

  InvoiceTotals({
    required this.productsTotal,
    required this.commission,
    required this.totalExpenses,
    required this.subTotal,
    required this.discountAmount,
    required this.gstAmount,
    required this.grandTotal,
    required this.pendingAmount,
  });

  double get expenses => totalExpenses;
  double get subtotal => subTotal;
  double get discount => discountAmount;
  double get pending => pendingAmount;
}

class InvoiceCalculationService {
  static InvoiceTotals calculate(InvoiceData invoice) {
    final productsTotal = invoice.products.fold<double>(0, (sum, p) {
      return sum + p.totalPrice;
    });

    final commission =
        (productsTotal * invoice.commissionPercent / 100) + invoice.fixedCommission;

    final totalExpenses = invoice.laborCharges +
        invoice.packingCharges +
        invoice.transportCharges +
        invoice.otherCharges;

    final subTotal = productsTotal + commission + totalExpenses;

    final discountAmount =
        invoice.manualDiscount + (subTotal * invoice.discountPercent / 100);

    final gstAmount = (subTotal - discountAmount) * invoice.gstPercent / 100;

    final grandTotal = subTotal - discountAmount + gstAmount;

    final pendingAmount = grandTotal - invoice.amountPaid;

    return InvoiceTotals(
      productsTotal: productsTotal,
      commission: commission,
      totalExpenses: totalExpenses,
      subTotal: subTotal,
      discountAmount: discountAmount,
      gstAmount: gstAmount,
      grandTotal: grandTotal,
      pendingAmount: pendingAmount,
    );
  }
}
