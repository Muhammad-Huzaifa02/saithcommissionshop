// Unit tests for the invoice money math and validation.
//
// These exist because this logic has broken silently before in this
// codebase: InvoiceData used to compute its own `grandTotal` with a
// formula that dropped commission and charges entirely, giving a
// DIFFERENT number than InvoiceCalculationService (which is what actually
// gets saved at checkout). The "totals stay consistent" group below is a
// regression test for that specific bug — if anyone reintroduces a
// second, separate total formula, this will fail.
//
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';
import 'package:saithcommissionshop/data/services/invoice_validation_service.dart';

InvoiceData _invoice({
  List<InvoiceProduct>? products,
  double commissionPercent = 0,
  double fixedCommission = 0,
  double laborCharges = 0,
  double packingCharges = 0,
  double transportCharges = 0,
  double otherCharges = 0,
  double discountPercent = 0,
  double manualDiscount = 0,
  double gstPercent = 0,
  double amountPaid = 0,
  String customerName = 'Test Customer',
  String customerPhone = '03001234567',
}) {
  return InvoiceData(
    invoiceNo: 'TEST-0001',
    customerId: 'cust-1',
    customerName: customerName,
    customerPhone: customerPhone,
    products: products ??
        const [
          InvoiceProduct(
            name: 'Gold Rice',
            productId: 'prod-1',
            pricePer40kg: 20000,
            bags50: 0,
            quantity: 1,
            weightPerUnit: 40,
          ),
        ],
    dateTime: DateTime(2026, 1, 1),
    commissionPercent: commissionPercent,
    fixedCommission: fixedCommission,
    laborCharges: laborCharges,
    packingCharges: packingCharges,
    transportCharges: transportCharges,
    otherCharges: otherCharges,
    discountPercent: discountPercent,
    manualDiscount: manualDiscount,
    gstPercent: gstPercent,
    amountPaid: amountPaid,
  );
}

void main() {
  group('InvoiceCalculationService.calculate', () {
    test('a bare invoice with no extras totals to just the products', () {
      final invoice = _invoice(); // 1 unit @ 40kg of a 40kg-priced product = 20000
      final totals = InvoiceCalculationService.calculate(invoice);

      expect(totals.productsTotal, 20000);
      expect(totals.commission, 0);
      expect(totals.totalExpenses, 0);
      expect(totals.subTotal, 20000);
      expect(totals.discountAmount, 0);
      expect(totals.gstAmount, 0);
      expect(totals.grandTotal, 20000);
      expect(totals.pendingAmount, 20000);
    });

    test('commission (percent + fixed) is added on top of the products total', () {
      final invoice = _invoice(commissionPercent: 5, fixedCommission: 100);
      final totals = InvoiceCalculationService.calculate(invoice);

      // 20000 * 5% = 1000, + 100 fixed = 1100
      expect(totals.commission, 1100);
      expect(totals.subTotal, 20000 + 1100);
    });

    test('labor/packing/transport/other charges are all added to the subtotal', () {
      final invoice = _invoice(
        laborCharges: 200,
        packingCharges: 150,
        transportCharges: 300,
        otherCharges: 50,
      );
      final totals = InvoiceCalculationService.calculate(invoice);

      expect(totals.totalExpenses, 200 + 150 + 300 + 50);
      expect(totals.subTotal, 20000 + 700);
    });

    test('discountPercent and manualDiscount combine before GST is applied', () {
      final invoice = _invoice(discountPercent: 10, manualDiscount: 500, gstPercent: 5);
      final totals = InvoiceCalculationService.calculate(invoice);

      // subTotal = 20000, discount = 500 + (20000 * 10%) = 2500
      expect(totals.discountAmount, 2500);
      // GST applies to the DISCOUNTED subtotal, not the raw subtotal.
      final expectedGst = (20000 - 2500) * 5 / 100;
      expect(totals.gstAmount, closeTo(expectedGst, 0.001));
      expect(totals.grandTotal, closeTo(20000 - 2500 + expectedGst, 0.001));
    });

    test('pendingAmount reflects amountPaid against the real grandTotal', () {
      final invoice = _invoice(commissionPercent: 5, amountPaid: 10000);
      final totals = InvoiceCalculationService.calculate(invoice);

      expect(totals.pendingAmount, closeTo(totals.grandTotal - 10000, 0.001));
    });

    test('multiple product lines sum correctly', () {
      final invoice = _invoice(products: const [
        InvoiceProduct(name: 'A', pricePer40kg: 20000, quantity: 1, weightPerUnit: 40),
        InvoiceProduct(name: 'B', pricePer40kg: 10000, quantity: 2, weightPerUnit: 40),
      ]);
      final totals = InvoiceCalculationService.calculate(invoice);

      // A: 40kg @ 20000/40kg = 20000. B: 80kg @ 10000/40kg = 20000.
      expect(totals.productsTotal, 40000);
    });
  });

  group('InvoiceData totals stay consistent with InvoiceCalculationService', () {
    // Regression test: these two used to disagree whenever commission or
    // charges were non-zero, because InvoiceData had its own separate
    // (incomplete) formula. They must always match now.
    test('grandTotal matches for an invoice with commission and charges', () {
      final invoice = _invoice(
        commissionPercent: 5,
        fixedCommission: 100,
        laborCharges: 200,
        packingCharges: 150,
        discountPercent: 10,
        gstPercent: 5,
      );

      final serviceTotal = InvoiceCalculationService.calculate(invoice).grandTotal;
      expect(invoice.grandTotal, closeTo(serviceTotal, 0.001));
      expect(invoice.subtotal, closeTo(InvoiceCalculationService.calculate(invoice).subTotal, 0.001));
      expect(invoice.gstAmount, closeTo(InvoiceCalculationService.calculate(invoice).gstAmount, 0.001));
    });

    test('grandTotal matches for a bare invoice with no extras', () {
      final invoice = _invoice();
      final serviceTotal = InvoiceCalculationService.calculate(invoice).grandTotal;
      expect(invoice.grandTotal, closeTo(serviceTotal, 0.001));
    });
  });

  group('InvoiceValidationService', () {
    test('rejects an empty customer name', () {
      final result = InvoiceValidationService.validate(_invoice(customerName: ''));
      expect(result.isValid, false);
      expect(result.errors, contains('Customer name is required'));
    });

    test('rejects an empty phone number', () {
      final result = InvoiceValidationService.validate(_invoice(customerPhone: ''));
      expect(result.isValid, false);
      expect(result.errors, contains('Phone number is required'));
    });

    test('rejects a badly-formatted phone number', () {
      final result = InvoiceValidationService.validate(_invoice(customerPhone: '12345'));
      expect(result.isValid, false);
      expect(
        result.errors.any((e) => e.contains('valid Pakistani phone number')),
        true,
      );
    });

    test('accepts a valid 03XXXXXXXXX number', () {
      final result = InvoiceValidationService.validate(_invoice(customerPhone: '03001234567'));
      expect(result.isValid, true);
    });

    test('accepts a valid +92 number', () {
      expect(InvoiceValidationService.isValidPakistaniPhone('+923001234567'), true);
    });

    test('accepts a valid 0092 number', () {
      expect(InvoiceValidationService.isValidPakistaniPhone('00923001234567'), true);
    });

    test('rejects a number missing the mobile-prefix 3', () {
      expect(InvoiceValidationService.isValidPakistaniPhone('04001234567'), false);
    });

    test('rejects an empty products list', () {
      final result = InvoiceValidationService.validate(_invoice(products: const []));
      expect(result.isValid, false);
      expect(result.errors, contains('Add at least one product'));
    });

    test('rejects a negative amountPaid', () {
      final result = InvoiceValidationService.validate(_invoice(amountPaid: -1));
      expect(result.isValid, false);
      expect(result.errors, contains('Paid amount cannot be negative'));
    });
  });
}
