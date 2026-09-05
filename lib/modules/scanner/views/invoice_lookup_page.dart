import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/data/services/pdf_invoice_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:printing/printing.dart';

class InvoiceLookupPage extends StatefulWidget {
  const InvoiceLookupPage({super.key});

  @override
  State<InvoiceLookupPage> createState() => _InvoiceLookupPageState();
}

class _InvoiceLookupPageState extends State<InvoiceLookupPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Scan Invoice'),
          backgroundColor: AppTheme.darkGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Scanner not supported on web'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Scan Invoice Barcode'),
        backgroundColor: AppTheme.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
            ),
            onDetect: (capture) {
              if (_isProcessing) {
                return;
              }
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _processInvoice(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the frame',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, backgroundColor: Colors.black45),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _processInvoice(String invoiceId) async {
    setState(() => _isProcessing = true);
    
    final ip = context.read<InvoiceProvider>();
    // Logic to find invoice by number or barcode field
    final invoice = ip.invoices.firstWhere(
      (inv) => inv.invoiceNo == invoiceId || inv.barcode == invoiceId,
      orElse: () => throw Exception('Invoice not found'),
    );

    try {
      if (!mounted) {
        return;
      }
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice Found', style: TextStyle(fontSize: 14, color: AppTheme.green, fontWeight: FontWeight.bold)),
                      Text(invoice.invoiceNo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: invoice.isPaid ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.isPaid ? 'PAID' : 'PENDING',
                      style: TextStyle(color: invoice.isPaid ? Colors.green[800] : Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _infoTile('Customer', invoice.customerName),
              _infoTile('Phone', invoice.customerPhone),
              _infoTile('Date', '${invoice.dateTime.day}/${invoice.dateTime.month}/${invoice.dateTime.year}'),
              _infoTile('Amount', 'PKR ${invoice.grandTotal.toStringAsFixed(0)}'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final file = await PdfInvoiceService.generate(invoice);
                    await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Download & View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Scan Another'),
                ),
              ),
            ],
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });

    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isProcessing = false);
    }
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}

