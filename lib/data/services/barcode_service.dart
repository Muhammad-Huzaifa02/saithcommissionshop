import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

enum BarcodeType { code128, code39, qrCode, ean13 }

class BarcodeService {
  // ── BARCODE WIDGET ────────────────────────────────────────────────────────
  static Widget generateBarcodeWidget({
    required String data,
    BarcodeType type = BarcodeType.code128,
    double width = 200,
    double height = 80,
    bool showValue = true,
  }) {
    return BarcodeWidget(
      barcode: _barcodeFor(type),
      data: data,
      width: width,
      height: height,
      drawText: showValue,
      style: const TextStyle(fontSize: 12),
    );
  }

  // ── QR CODE WIDGET ────────────────────────────────────────────────────────
  static Widget generateQRCode({
    required String data,
    double size = 200,
    Color color = Colors.black,
  }) {
    return BarcodeWidget(
      barcode: Barcode.qrCode(),
      data: data,
      width: size,
      height: size,
      color: color,
    );
  }

  // ── SHOW BARCODE DIALOG ───────────────────────────────────────────────────
  static void showBarcodeDialog({
    required BuildContext context,
    required String data,
    required String title,
    BarcodeType type = BarcodeType.code128,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            generateBarcodeWidget(data: data, type: type, width: 250, height: 100),
            const SizedBox(height: 12),
            Text(data, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // ── SHOW QR DIALOG ────────────────────────────────────────────────────────
  static void showQRCodeDialog({
    required BuildContext context,
    required String data,
    required String title,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            generateQRCode(data: data, size: 240),
            const SizedBox(height: 12),
            Text('Scan Invoice Number', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  static Barcode _barcodeFor(BarcodeType type) {
    switch (type) {
      case BarcodeType.code128: return Barcode.code128();
      case BarcodeType.code39:  return Barcode.code39();
      case BarcodeType.qrCode:  return Barcode.qrCode();
      case BarcodeType.ean13:   return Barcode.ean13();
    }
  }
}