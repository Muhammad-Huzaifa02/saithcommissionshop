import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class InvoiceScannerPage extends StatefulWidget {
  /// If [onProductScanned] is provided, scanning returns a product to add to cart/invoice
  final void Function(InvoiceProduct product)? onProductScanned;
  const InvoiceScannerPage({super.key, this.onProductScanned});

  @override
  State<InvoiceScannerPage> createState() => _InvoiceScannerPageState();
}

class _InvoiceScannerPageState extends State<InvoiceScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing:         CameraFacing.back,
    torchEnabled:   false,
  );

  bool  _scanned   = false;
  bool  _torchOn   = false;
  String? _lastCode;
  Timer?  _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final code = barcode!.rawValue!;
    if (code == _lastCode) return;

    // Use unawaited from dart:async to stop camera without blocking UI
    unawaited(_ctrl.stop());

    setState(() {
      _scanned = true;
      _lastCode = code;
    });

    _processCode(code);

    // Use Timer from dart:async to clear the "last code" cache after 10 seconds 
    // This allows the user to re-scan the same item if they decide to later.
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _lastCode = null;
    });
  }

  void _processCode(String code) {
    final pp = context.read<ProductProvider>();

    // Try to find product by name or ID from barcode
    final product = pp.getProductById(code) ?? pp.getProductByName(code);

    if (product != null) {
      // Product found — show confirm sheet
      _showProductConfirm(product, code);
    } else {
      // Not a product ID — maybe invoice number or general code
      _showCodeResult(code);
    }
  }

  void _showProductConfirm(dynamic product, String code) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductConfirmSheet(
        product:           product,
        code:              code,
        onAdd:             (qty) {
          final scanResult = InvoiceProduct(
            name:          product.name,
            productId:     product.id,
            pricePer40kg:  product.pricePer40kg,
            bags50:        qty.toInt(),
          );
          if (widget.onProductScanned != null) {
            widget.onProductScanned!(scanResult);
            Navigator.pop(context); // Close sheet
            Navigator.pop(context); // Close scanner
          } else {
            Navigator.pop(context); // Close sheet
            Navigator.pop(context, scanResult); // Return to caller
          }
        },
        onRescan: () {
          Navigator.pop(context);
          setState(() { _scanned = false; _lastCode = null; });
          _ctrl.start();
        },
      ),
    );
  }

  void _showCodeResult(String code) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 48, color: SColors.primary),
            const SizedBox(height: 12),
            const Text('Code Scanned', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SColors.surfaceAlt,
                borderRadius: SRadius.radiusMd,
              ),
              child: Text(code, style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            Text(
              'No product found for this code.\nThis may be an invoice or order number.',
              style: TextStyle(color: SColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() { _scanned = false; _lastCode = null; });
                    _ctrl.start();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, code);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Use Code'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Scan Barcode / QR',
      actions: [
        IconButton(
          icon: Icon(_torchOn ? Icons.flash_off : Icons.flash_on,
              color: _torchOn ? Colors.yellow : Colors.white),
          onPressed: () {
            _ctrl.toggleTorch();
            setState(() => _torchOn = !_torchOn);
          },
          tooltip: 'Toggle Torch',
        ),
        IconButton(
          icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white),
          onPressed: _ctrl.switchCamera,
          tooltip: 'Flip Camera',
        ),
      ],
      body: Stack(
        children: [
          // ── Camera ─────────────────────────────────────────────────
          MobileScanner(
            controller: _ctrl,
            onDetect: _onDetect,
          ),

          // ── Overlay ─────────────────────────────────────────────────
          _ScannerOverlay(scanned: _scanned),

          // ── Bottom hint ──────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              child: Column(children: [
                ResponsiveText(
                  _scanned
                      ? '✓ Code detected — processing...'
                      : 'Point camera at product barcode or invoice QR code',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const ResponsiveText('Barcode • QR Code • Product ID',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scanner Overlay ────────────────────────────────────────────────────────
class _ScannerOverlay extends StatelessWidget {
  final bool scanned;
  const _ScannerOverlay({required this.scanned});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(scanned: scanned),
      child: Container(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool scanned;
  _OverlayPainter({required this.scanned});

  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * 0.65;
    final left   = (size.width  - scanAreaSize) / 2;
    final top    = (size.height - scanAreaSize) / 2.2;
    final rect   = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);

    // Corner brackets
    final bracketColor = scanned ? SColors.success : Colors.white;
    final bracketPaint = Paint()
      ..color = bracketColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 24.0;

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(left, top + len) ..lineTo(left, top) ..lineTo(left + len, top), bracketPaint);
    // Top-right
    canvas.drawPath(Path()
      ..moveTo(left + scanAreaSize - len, top)
      ..lineTo(left + scanAreaSize, top)
      ..lineTo(left + scanAreaSize, top + len), bracketPaint);
    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(left, top + scanAreaSize - len)
      ..lineTo(left, top + scanAreaSize)
      ..lineTo(left + len, top + scanAreaSize), bracketPaint);
    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(left + scanAreaSize - len, top + scanAreaSize)
      ..lineTo(left + scanAreaSize, top + scanAreaSize)
      ..lineTo(left + scanAreaSize, top + scanAreaSize - len), bracketPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.scanned != scanned;
}

// ── Product Confirm Sheet ──────────────────────────────────────────────────
class _ProductConfirmSheet extends StatefulWidget {
  final dynamic product;
  final String  code;
  final void Function(double qty) onAdd;
  final VoidCallback onRescan;
  const _ProductConfirmSheet({
    required this.product,
    required this.code,
    required this.onAdd,
    required this.onRescan,
  });

  @override
  State<_ProductConfirmSheet> createState() => _ProductConfirmSheetState();
}

class _ProductConfirmSheetState extends State<_ProductConfirmSheet> {
  double _qty = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: SColors.primary.withValues(alpha: 0.1),
                  borderRadius: SRadius.radiusMd),
              child: Icon(Icons.grain, color: SColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17)),
                Text('PKR ${p.pricePer40kg.toStringAsFixed(0)} per 40kg  •  '
                    '${p.availableStockKg.toStringAsFixed(0)} kg in stock',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: p.isOutOfStock
                    ? SColors.error.withValues(alpha: 0.1)
                    : SColors.success.withValues(alpha: 0.1),
                borderRadius: SRadius.radiusSm,
              ),
              child: Text(p.isOutOfStock ? 'Out' : 'In Stock',
                  style: TextStyle(
                      color: p.isOutOfStock ? SColors.error : SColors.success,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 20),

          // Quantity selector
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Bags:', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 16),
            _QtyButton(Icons.remove, () => setState(() { if (_qty > 1) _qty--; })),
            const SizedBox(width: 16),
            Text('${_qty.toInt()}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            _QtyButton(Icons.add, () => setState(() => _qty++)),
          ]),
          const SizedBox(height: 8),
          Text('Total: PKR ${(p.pricePer40kg * _qty).toStringAsFixed(0)}',
              style: TextStyle(color: SColors.primary,
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRescan,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: p.isOutOfStock ? null : () => widget.onAdd(_qty),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Invoice'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

Widget _QtyButton(IconData icon, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
        color: SColors.primary.withValues(alpha: 0.1),
        borderRadius: SRadius.radiusMd),
    child: Icon(icon, color: SColors.primary),
  ),
);
