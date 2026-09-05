import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/ledger_entry.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class InvoiceTransactionService {
  static Future<void> saveInvoice({
    required InvoiceData invoice,
    required InvoiceProvider invoiceProvider,
    required ProductProvider productProvider,
    required LedgerProvider ledgerProvider,
  }) async {
    try {
      final totals = InvoiceCalculationService.calculate(invoice);

      // Build stock deductions. We match by productId (stable) rather than
      // name (fragile — renames/whitespace/duplicates break it silently).
      // Items with no productId are free-text manual-invoice lines that
      // aren't tied to a catalog product, so they intentionally have no
      // stock effect. If a line HAS a productId but it can't be resolved
      // against the loaded catalog, we fail loudly instead of silently
      // completing the sale without deducting stock.
      final List<Map<String, dynamic>> stockDeductions = [];

      for (final item in invoice.products) {
        if (item.productId == null || item.productId!.isEmpty) continue;

        final matches = productProvider.products.where((p) => p.id == item.productId);
        if (matches.isEmpty) {
          throw Exception(
            'Product "${item.name}" (id: ${item.productId}) could not be found in the '
            'catalog — refusing to complete this sale rather than skip its stock deduction.',
          );
        }

        stockDeductions.add({
          'productId': item.productId,
          'name':      item.name,
          'changeKg':  -item.totalWeightKg,
          'reference': invoice.invoiceNo,
          'adminId':   invoice.customerId, // For customer orders, use their ID as reference
          'notes':     'Deducted via Checkout (Invoice ${invoice.invoiceNo})',
        });
      }

      // Prepare ledger data
      final ledgerData = {
        'customerId':  invoice.customerId,
        'type':        LedgerType.invoice.name,
        'debit':       totals.grandTotal,
        'credit':      invoice.amountPaid,
        'balance':     totals.pendingAmount,
        'description': 'Invoice ${invoice.invoiceNo}',
        'invoiceNo':   invoice.invoiceNo,
      };

      // Prepare invoice data
      final invoiceMap = {
        'customerId':       invoice.customerId,
        'customerName':     invoice.customerName,
        'customerPhone':    invoice.customerPhone,
        'customerDisplayId': invoice.customerDisplayId,
        'dateTime':         FieldValue.serverTimestamp(), // Use server time
        'products': invoice.products.map((p) => {
          'name':          p.name,
          'productId':     p.productId,
          'pricePer40kg':  p.pricePer40kg,
          'quantity':      p.quantity,
          'weightPerUnit': p.weightPerUnit,
          'bags50':        p.bags50,
          'bags100':       p.bags100,
          'looseWeightKg': p.looseWeightKg,
        }).toList(),
        'paymentMethod':    invoice.paymentMethod,
        'isPaid':           invoice.isPaid,
        'notes':            invoice.notes,
        'grandTotal':       totals.grandTotal,
        'subtotal':         totals.subtotal,
        'gstPercent':       invoice.gstPercent,
        'discountPercent':  invoice.discountPercent,
        'manualDiscount':   invoice.manualDiscount,
        'commissionPercent':invoice.commissionPercent,
        'fixedCommission':  invoice.fixedCommission,
        'laborCharges':     invoice.laborCharges,
        'packingCharges':   invoice.packingCharges,
        'transportCharges': invoice.transportCharges,
        'otherCharges':     invoice.otherCharges,
        'amountPaid':       invoice.amountPaid,
      };

      // Perform atomic transaction — stock is read fresh and validated
      // at commit time, so this either fully succeeds or fully fails.
      await FirebaseService.saveInvoiceTransaction(
        invoiceId:        invoice.invoiceNo,
        invoiceData:      invoiceMap,
        stockDeductions:  stockDeductions,
        ledgerData:       ledgerData,
      );

      debugPrint('Invoice transaction completed successfully for ${invoice.invoiceNo}');
    } catch (e) {
      debugPrint('Error saving invoice transaction: $e');
      rethrow;
    }
  }
}
