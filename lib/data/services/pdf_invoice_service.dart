import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';

class PdfInvoiceService {
  static Future<File> generate(InvoiceData invoice) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SAITH COMMISSION SHOP',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Gala Mandi Wahndo Shop # 6, Gujranwala',
                        style: const pw.TextStyle(
                            color: PdfColor(1, 1, 1, 0.7), fontSize: 11)),
                    pw.Text('Tel: 03055496500',
                        style: const pw.TextStyle(
                            color: PdfColor(1, 1, 1, 0.7), fontSize: 11)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.invoiceNo,
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Customer + Date ───────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILL TO',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.customerName,
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.customerPhone,
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('ID: ${invoice.customerId}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE DATE',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.Text(
                        '${invoice.dateTime.day}/${invoice.dateTime.month}/${invoice.dateTime.year}',
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Text('PAYMENT METHOD',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.Text(invoice.paymentMethod.toUpperCase(),
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Text('STATUS',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: invoice.isPaid
                            ? PdfColors.green100
                            : PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        invoice.isPaid ? 'PAID' : 'PENDING',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: invoice.isPaid
                              ? PdfColors.green800
                              : PdfColors.orange800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // ── Products Table ────────────────────────────────────
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Product', 'Weight Details', 'Total Wt', 'Rate/40kg', 'Amount'],
            data: invoice.products.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              
              List<String> details = [];
              if (p.bags50 > 0) details.add('${p.bags50}x50kg');
              if (p.bags100 > 0) details.add('${p.bags100}x100kg');
              if (p.looseWeightKg > 0) details.add('${p.looseWeightKg}kg loose');
              if (p.quantity > 0) details.add('${p.quantity.toStringAsFixed(0)}x40kg');
              
              return [
                '${i + 1}',
                p.name,
                details.join('\n'),
                '${p.totalWeightKg.toStringAsFixed(1)} kg',
                'PKR ${p.pricePer40kg.toStringAsFixed(0)}',
                'PKR ${p.totalPrice.toStringAsFixed(0)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration:
            const pw.BoxDecoration(color: PdfColors.green700),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            oddRowDecoration:
            const pw.BoxDecoration(color: PdfColors.grey100),
          ),
          pw.SizedBox(height: 16),

          // ── Totals & Barcode ──────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Barcode on the left
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 120,
                    height: 60,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: invoice.barcode ?? invoice.invoiceNo,
                      drawText: true,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Scan to verify invoice', 
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
              pw.Spacer(),
              // Totals on the right
              pw.Container(
                width: 200,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal', 'PKR ${invoice.subtotal.toStringAsFixed(0)}'),
                    if (invoice.discountAmt > 0 || invoice.manualDiscount > 0)
                      _totalRow('Discount', '- PKR ${(invoice.discountAmt + invoice.manualDiscount).toStringAsFixed(0)}',
                          color: PdfColors.green700),
                    if (invoice.gstRate > 0 || invoice.gstPercent > 0)
                      _totalRow(
                          'GST',
                          'PKR ${invoice.gstAmount.toStringAsFixed(0)}'),
                    pw.Divider(),
                    _totalRow('GRAND TOTAL', 'PKR ${invoice.grandTotal.toStringAsFixed(0)}', 
                        isBold: true, color: PdfColors.green800),
                    if (invoice.amountPaid > 0)
                      _totalRow('Amount Paid', 'PKR ${invoice.amountPaid.toStringAsFixed(0)}'),
                    if ((invoice.grandTotal - invoice.amountPaid) > 0.5)
                      _totalRow('Balance Due', 'PKR ${(invoice.grandTotal - invoice.amountPaid).toStringAsFixed(0)}',
                          isBold: true, color: PdfColors.red800),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          // ── Notes ─────────────────────────────────────────────
          if (invoice.notes.isNotEmpty) ...[
            pw.Text('Notes:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.Text(invoice.notes,
                style: const pw.TextStyle(
                    color: PdfColors.grey600, fontSize: 11)),
            pw.SizedBox(height: 20),
          ],

          // ── Footer ────────────────────────────────────────────
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                  color: PdfColors.green800,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Saith Commission Shop • Gala Mandi Wahndo Shop # 6, Gujranwala • 🇵🇰',
              style: const pw.TextStyle(
                  color: PdfColors.grey, fontSize: 10),
            ),
          ),
        ],
      ),
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${invoice.invoiceNo}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _totalRow(String label, String value,
      {PdfColor color = PdfColors.black, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
              pw.TextStyle(color: PdfColors.grey700, fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : null)),
          pw.Text(value,
              style: pw.TextStyle(color: color, fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }
}
