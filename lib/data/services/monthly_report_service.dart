import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';

class MonthlyReportService {
  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static Future<File> generateMonthlyReport({
    required List<InvoiceData> invoices,
    required List<Product> products,
    required int month,
    required int year,
  }) async {
    final monthInvoices = invoices
        .where((i) => i.dateTime.month == month && i.dateTime.year == year)
        .toList();

    final totalSales   = monthInvoices.fold(0.0, (s, i) => s + i.grandTotal);
    final totalPaid    = monthInvoices.where((i) => i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);
    final totalPending = monthInvoices.where((i) => !i.isPaid).fold(0.0, (s, i) => s + i.grandTotal);
    final totalOrders  = monthInvoices.length;

    // Product-wise sales
    final productSales = <String, double>{};
    for (final inv in monthInvoices) {
      for (final p in inv.products) {
        productSales[p.name] = (productSales[p.name] ?? 0) + p.totalPrice;
      }
    }
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // ── Header ───────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.green800,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SAITH COMMISSION SHOP',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Monthly Sales Report — ${_monthNames[month]} $year',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 14)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 11)),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // ── Summary ───────────────────────────────────────────
        pw.Text('Summary',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Total Orders', '$totalOrders'],
            ['Total Sales', 'PKR ${totalSales.toStringAsFixed(0)}'],
            ['Amount Paid', 'PKR ${totalPaid.toStringAsFixed(0)}'],
            ['Amount Pending', 'PKR ${totalPending.toStringAsFixed(0)}'],
            ['Average Order Value',
              totalOrders > 0
                  ? 'PKR ${(totalSales / totalOrders).toStringAsFixed(0)}'
                  : 'PKR 0'],
          ],
          headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration:
          const pw.BoxDecoration(color: PdfColors.green700),
          cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
        ),
        pw.SizedBox(height: 24),

        // ── Product Performance ───────────────────────────────
        pw.Text('Product Performance',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (topProducts.isEmpty)
          pw.Text('No sales data for this month.',
              style: pw.TextStyle(color: PdfColors.grey))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Sales (PKR)', 'Share %'],
            data: topProducts
                .map((e) => [
              e.key,
              'PKR ${e.value.toStringAsFixed(0)}',
              totalSales > 0
                  ? '${(e.value / totalSales * 100).toStringAsFixed(1)}%'
                  : '0%',
            ])
                .toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.green700),
            cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
          ),
        pw.SizedBox(height: 24),

        // ── Invoice List ──────────────────────────────────────
        pw.Text('Invoice List',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (monthInvoices.isEmpty)
          pw.Text('No invoices for this month.',
              style: pw.TextStyle(color: PdfColors.grey))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Invoice No', 'Customer', 'Date', 'Amount', 'Status'],
            data: monthInvoices
                .map((inv) => [
              inv.invoiceNo,
              inv.customerName,
              '${inv.dateTime.day}/${inv.dateTime.month}',
              'PKR ${inv.grandTotal.toStringAsFixed(0)}',
              inv.isPaid ? 'Paid' : 'Pending',
            ])
                .toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.green700),
            cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8, vertical: 5),
          ),

        pw.SizedBox(height: 32),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Saith Commission Shop • Lahore, Pakistan',
            style: pw.TextStyle(
                color: PdfColors.green800,
                fontWeight: pw.FontWeight.bold,
                fontSize: 12),
          ),
        ),
      ],
    ));

    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_${_monthNames[month]}_$year.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
