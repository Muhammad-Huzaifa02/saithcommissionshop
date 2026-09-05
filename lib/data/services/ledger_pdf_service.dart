import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saithcommissionshop/data/models/ledger_entry.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';

class LedgerPdfService {
  // ── Generate PDF ───────────────────────────────────────────────────────────
  static Future<File> generate({
    required String   customerId,
    required String   customerName,
    required String   customerPhone,
    required List<LedgerEntry> entries,
    String shopName    = 'Saith Commission Shop',
    String shopAddress = 'Lahore, Pakistan',
  }) async {
    final pdf     = pw.Document();
    final now     = DateTime.now();
    double running = 0;

    // Build table rows
    final rows = <List<String>>[];
    for (final e in entries) {
      running += e.debit - e.credit;
      rows.add([
        PakistanFormatter.formatDate(e.dateTime),
        e.description,
        e.debit  > 0 ? 'PKR ${e.debit.toStringAsFixed(0)}'  : '—',
        e.credit > 0 ? 'PKR ${e.credit.toStringAsFixed(0)}' : '—',
        'PKR ${running.toStringAsFixed(0)}',
      ]);
    }

    final balance  = running;
    final isPending = balance > 0;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:     const pw.EdgeInsets.all(36),
      header:     (_) => _buildHeader(shopName, shopAddress, now),
      footer:     (ctx) => _buildFooter(ctx, shopName),
      build:      (ctx) => [
        // ── Customer info ───────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('LEDGER STATEMENT',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800)),
                pw.SizedBox(height: 4),
                pw.Text('Customer: $customerName',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Phone: $customerPhone'),
                pw.Text('Customer ID: $customerId',
                    style: const pw.TextStyle(color: PdfColors.grey)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Date: ${PakistanFormatter.formatDate(now)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Total Transactions: ${entries.length}'),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: isPending ? PdfColors.red50 : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    isPending ? 'OUTSTANDING' : 'CLEARED',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: isPending ? PdfColors.red700 : PdfColors.green700,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // ── Transactions table ──────────────────────────────────────────
        if (rows.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Description', 'Debit (Dr)', 'Credit (Cr)', 'Balance'],
            data:    rows,
            border:  pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellStyle:  const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          )
        else
          pw.Center(child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Text('No transactions found',
                style: const pw.TextStyle(color: PdfColors.grey)),
          )),
        pw.SizedBox(height: 16),

        // ── Balance summary ─────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: isPending ? PdfColors.red50 : PdfColors.green50,
            border: pw.Border.all(
                color: isPending ? PdfColors.red300 : PdfColors.green300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isPending ? 'Outstanding Balance:' : 'Account Status:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 13,
                    color: isPending ? PdfColors.red700 : PdfColors.green700),
              ),
              pw.Text(
                isPending
                    ? 'PKR ${balance.toStringAsFixed(0)}'
                    : 'CLEARED ✓',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 14,
                    color: isPending ? PdfColors.red700 : PdfColors.green700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // ── Summary stats ───────────────────────────────────────────────
        pw.Row(children: [
          _SummaryBox('Total Debit',
              'PKR ${entries.fold(0.0, (s, e) => s + e.debit).toStringAsFixed(0)}',
              PdfColors.red800),
          pw.SizedBox(width: 8),
          _SummaryBox('Total Credit',
              'PKR ${entries.fold(0.0, (s, e) => s + e.credit).toStringAsFixed(0)}',
              PdfColors.green800),
          pw.SizedBox(width: 8),
          _SummaryBox('Net Balance',
              'PKR ${balance.abs().toStringAsFixed(0)}',
              isPending ? PdfColors.orange800 : PdfColors.green800),
        ]),
      ],
    ));

    final dir  = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ledger_${customerName.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Share PDF ──────────────────────────────────────────────────────────────
  static Future<void> shareStatement({
    required String   customerId,
    required String   customerName,
    required String   customerPhone,
    required List<LedgerEntry> entries,
  }) async {
    final file = await generate(
      customerId:    customerId,
      customerName:  customerName,
      customerPhone: customerPhone,
      entries:       entries,
    );
    final balance = entries.fold(0.0, (s, e) => s + e.debit - e.credit);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Ledger Statement — $customerName',
      text: 'Ledger Statement for $customerName\n'
          'Balance: PKR ${balance.toStringAsFixed(0)}\n'
          'Transactions: ${entries.length}\n\n'
          'Saith Commission Shop',
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(String shopName, String address, DateTime now) =>
      pw.Column(children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(shopName,
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800)),
              pw.Text(address,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ]),
            pw.Text('🇵🇰 Pakistan',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ],
        ),
        pw.Divider(color: PdfColors.green800, thickness: 1.5),
        pw.SizedBox(height: 8),
      ]);

  static pw.Widget _buildFooter(pw.Context ctx, String shopName) =>
      pw.Column(children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(shopName,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ]);

  static pw.Widget _SummaryBox(String label, String value, PdfColor color) =>
      pw.Expanded(child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold,
              fontSize: 11, color: color)),
        ]),
      ));
}
