import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class InvoiceProduct {
  final String name;
  // Firestore product doc ID this line item corresponds to, if any. Used to
  // find and deduct stock reliably — matching by `name` is fragile (renames,
  // whitespace, duplicates). Null for free-text line items on manual admin
  // invoices that aren't tied to a catalog product (no stock to deduct).
  final String? productId;
  final double pricePer40kg;
  final int bags50;
  final int bags100;
  final double looseWeightKg;
  final double quantity; // Legacy/Backwards compat: number of 40kg units or bags
  final double weightPerUnit; // Legacy

  const InvoiceProduct({
    required this.name,
    this.productId,
    required this.pricePer40kg,
    this.bags50 = 0,
    this.bags100 = 0,
    this.looseWeightKg = 0,
    this.quantity = 0,
    this.weightPerUnit = 0,
  });

  double get totalWeightKg => 
      (bags50 * 50.0) + (bags100 * 100.0) + looseWeightKg + (quantity * (weightPerUnit > 0 ? weightPerUnit : 50.0));
  
  double get totalPrice => (totalWeightKg / 40.0) * pricePer40kg;
  double get totalAmount => totalPrice;

  InvoiceProduct copyWith({
    String? name,
    String? productId,
    double? pricePer40kg,
    int? bags50,
    int? bags100,
    double? looseWeightKg,
    double? quantity,
    double? weightPerUnit,
  }) =>
      InvoiceProduct(
        name: name ?? this.name,
        productId: productId ?? this.productId,
        pricePer40kg: pricePer40kg ?? this.pricePer40kg,
        bags50: bags50 ?? this.bags50,
        bags100: bags100 ?? this.bags100,
        looseWeightKg: looseWeightKg ?? this.looseWeightKg,
        quantity: quantity ?? this.quantity,
        weightPerUnit: weightPerUnit ?? this.weightPerUnit,
      );
}

class InvoiceData {
  final String invoiceNo;
  final String customerId; // Technical UID
  final String customerName;
  final String customerPhone;
  final String? customerDisplayId; // Professional ID like CUST-0001
  final List<InvoiceProduct> products;
  final DateTime dateTime;
  final String paymentMethod;
  final bool isPaid;
  final String notes;
  final String? barcode;

  // GST & discount
  final double gstRate;         // 0.05 = 5%
  final double gstPercent;      // alias: 5.0 = 5%
  final double discountAmt;
  final double discountPercent;
  final double manualDiscount;

  // Commission fields (legacy services)
  final double commissionPercent;
  final double fixedCommission;

  // Charges (legacy services)
  final double laborCharges;
  final double packingCharges;
  final double transportCharges;
  final double otherCharges;

  // Payment tracking
  final double amountPaid;

  const InvoiceData({
    required this.invoiceNo,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerDisplayId,
    required this.products,
    required this.dateTime,
    this.paymentMethod = 'cash',
    this.isPaid = true,
    this.notes = '',
    this.barcode,
    this.gstRate = 0.0,
    this.gstPercent = 0.0,
    this.discountAmt = 0.0,
    this.discountPercent = 0.0,
    this.manualDiscount = 0.0,
    this.commissionPercent = 0.0,
    this.fixedCommission = 0.0,
    this.laborCharges = 0.0,
    this.packingCharges = 0.0,
    this.transportCharges = 0.0,
    this.otherCharges = 0.0,
    this.amountPaid = 0.0,
  });

  // These delegate to InvoiceCalculationService — the single source of
  // truth for totals (includes commission, labor/packing/transport/other
  // charges, and discountPercent). They previously used a separate,
  // simpler formula here that silently dropped all of that, so most of
  // the app displayed a different (lower) total than what was actually
  // saved at checkout for any invoice with commission or charges set.
  double get subtotal => InvoiceCalculationService.calculate(this).subTotal;

  double get gstAmount => InvoiceCalculationService.calculate(this).gstAmount;

  double get grandTotal => InvoiceCalculationService.calculate(this).grandTotal;

  // Alias used by old services
  double get totalAmount => grandTotal;

  InvoiceData copyWith({
    bool? isPaid,
    String? paymentMethod,
    double? amountPaid,
  }) =>
      InvoiceData(
        invoiceNo: invoiceNo,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerDisplayId: customerDisplayId,
        products: products,
        dateTime: dateTime,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        isPaid: isPaid ?? this.isPaid,
        notes: notes,
        gstRate: gstRate,
        gstPercent: gstPercent,
        discountAmt: discountAmt,
        discountPercent: discountPercent,
        manualDiscount: manualDiscount,
        commissionPercent: commissionPercent,
        fixedCommission: fixedCommission,
        laborCharges: laborCharges,
        packingCharges: packingCharges,
        transportCharges: transportCharges,
        otherCharges: otherCharges,
        amountPaid: amountPaid ?? this.amountPaid,
      );
}
