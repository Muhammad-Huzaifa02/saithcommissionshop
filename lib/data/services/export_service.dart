import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';

class ExportService {
  // ── INVOICES → EXCEL ──────────────────────────────────────────────────────
  static Future<File> exportInvoicesToExcel(
      List<InvoiceData> invoices) async {
    final excel = Excel.createExcel();
    final sheet = excel['Invoices'];

    sheet.appendRow([
      TextCellValue('Invoice No'),
      TextCellValue('Customer'),
      TextCellValue('Phone'),
      TextCellValue('Date'),
      TextCellValue('Products'),
      TextCellValue('Grand Total'),
      TextCellValue('Amount Paid'),
      TextCellValue('Pending'),
      TextCellValue('Status'),
    ]);

    for (var inv in invoices) {
      final calc = InvoiceCalculationService.calculate(inv);
      sheet.appendRow([
        TextCellValue(inv.invoiceNo),
        TextCellValue(inv.customerName),
        TextCellValue(inv.customerPhone),
        TextCellValue(
            '${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year}'),
        TextCellValue(inv.products
            .map((p) => '${p.name} x${p.quantity}')
            .join(', ')),
        DoubleCellValue(calc.grandTotal),
        DoubleCellValue(inv.amountPaid),
        DoubleCellValue(calc.pendingAmount),
        TextCellValue(
            inv.amountPaid >= calc.grandTotal ? 'Paid' : 'Pending'),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/invoices_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  // ── PRODUCTS → EXCEL ──────────────────────────────────────────────────────
  static Future<File> exportProductsToExcel(
      List<Product> products) async {
    final excel = Excel.createExcel();
    final sheet = excel['Products'];

    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Category'),
      TextCellValue('Price/40kg (PKR)'),
      TextCellValue('Stock (kg)'),
      TextCellValue('Stock Value (PKR)'),
    ]);

    for (var p in products) {
      sheet.appendRow([
        TextCellValue(p.name),
        TextCellValue(p.category ?? 'Rice'),
        DoubleCellValue(p.pricePer40kg),
        DoubleCellValue(p.availableStockKg),
        DoubleCellValue(p.stockValue),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/products_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  // ── SUMMARY CSV ───────────────────────────────────────────────────────────
  static Future<File> exportSummaryCSV(
      List<InvoiceData> invoices) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Invoice No,Customer,Date,Total,Paid,Pending,Status');

    for (var inv in invoices) {
      final calc = InvoiceCalculationService.calculate(inv);
      buffer.writeln('${inv.invoiceNo},${inv.customerName},'
          '${inv.dateTime.day}/${inv.dateTime.month}/${inv.dateTime.year},'
          '${calc.grandTotal.toStringAsFixed(0)},'
          '${inv.amountPaid.toStringAsFixed(0)},'
          '${calc.pendingAmount.toStringAsFixed(0)},'
          '${inv.amountPaid >= calc.grandTotal ? "Paid" : "Pending"}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/summary_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());
    return file;
  }
}
