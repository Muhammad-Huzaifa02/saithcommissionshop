import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/cart/providers/cart_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/repositories/invoice_transaction_service.dart';
import 'package:saithcommissionshop/data/services/invoice_validation_service.dart';
import 'package:saithcommissionshop/core/utils/overflow_handler.dart';


class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _nameCtrl    = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _paymentMethod = 'cash';
  bool _isPlacing = false;

  static const _paymentMethods = [
    {'id': 'cash',      'en': 'Cash on Delivery', 'icon': Icons.delivery_dining,        'color': SColors.primary},
    {'id': 'card',      'en': 'Credit / Debit Card', 'icon': Icons.credit_card,          'color': SColors.catBlue},
    {'id': 'bank',      'en': 'Bank Transfer',    'icon': Icons.account_balance,         'color': SColors.catIndigo},
    {'id': 'credit',    'en': 'Udhaar (Credit)',  'icon': Icons.history,                 'color': SColors.catOrange},
  ];

  @override
  void initState() {
    super.initState();
    final customer = context.read<CustomerProvider>().currentCustomer;
    if (customer != null) {
      _nameCtrl.text    = customer.name;
      _addressCtrl.text = customer.address;
      _phoneCtrl.text   = customer.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose();
    _phoneCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  String _transactionId = '';

  Future<void> _placeOrder() async {
    final cart     = context.read<CartProvider>();
    final customer = context.read<CustomerProvider>().currentCustomer;

    if (cart.items.isEmpty) {
      _snack('Your cart is empty', SColors.warning);
      return;
    }

    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      _snack('Name and phone are required', SColors.error);
      return;
    }

    if (!InvoiceValidationService.isValidPakistaniPhone(_phoneCtrl.text)) {
      _snack('Enter a valid phone number (e.g. 03XXXXXXXXX) — invoices are sent via WhatsApp/SMS', SColors.error);
      return;
    }

    if ((_paymentMethod == 'card' || _paymentMethod == 'bank') && _transactionId.isEmpty) {
      _showPaymentInstructions();
      return;
    }

    setState(() => _isPlacing = true);

    try {
      // ── CRITICAL: Check Firebase Auth session ──────────────────
      // Firestore rules (request.auth != null) will fail if this is null
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        throw 'Your session has expired. Please sign out and sign in again to place orders.';
      }

      final ip = context.read<InvoiceProvider>();
      final invoiceNo = ip.nextInvoiceNo;

      // Initial invoice to calculate totals
      final initialInvoice = InvoiceData(
        invoiceNo:    invoiceNo,
        customerId:   customer?.id ?? 'guest',
        customerDisplayId: customer?.customerId ?? 'GUEST',
        customerName: _nameCtrl.text,
        customerPhone: _phoneCtrl.text,
        products:     cart.items,
        dateTime:     DateTime.now(),
        paymentMethod: _paymentMethod,
        notes:        '${_notesCtrl.text}'
            '${_transactionId.isNotEmpty ? "\n⚠ PAYMENT PENDING VERIFICATION — Customer-reported ref: $_transactionId" : ""}',
      );

      // NOTE: card/bank payments are NOT verified against any gateway here —
      // there is no payment gateway integration wired into this app. The
      // customer's transaction ID is just a self-reported reference, so we
      // must never treat it as proof of payment. All orders are created as
      // unpaid; an admin verifies the transaction ID and marks the invoice
      // paid afterwards (via admin_manual_invoice_page / ledger).
      final finalInvoice = initialInvoice.copyWith(
        isPaid:       false,
        amountPaid:   0.0,
      );

      await InvoiceTransactionService.saveInvoice(
        invoice: finalInvoice,
        invoiceProvider: context.read<InvoiceProvider>(),
        productProvider: context.read<ProductProvider>(),
        ledgerProvider: context.read<LedgerProvider>(),
      );

      cart.clear();
      if (!mounted || !context.mounted) return;
      _showSuccessDialog(invoiceNo);
    } catch (e) {
      debugPrint('Error placing order: $e');
      if (!mounted || !context.mounted) return;
      
      String msg = e.toString();
      if (msg.contains('permission-denied')) {
        msg = 'Permission Denied: Please check your Internet connection or contact support to verify your account status.';
      } else if (msg.contains('not-found')) {
        msg = 'Resource not found. Please try again.';
      }

      _snack(msg, SColors.error);
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _showPaymentInstructions() {
    String title = '';
    String details = '';
    Color color = SColors.success;
    IconData icon = Icons.payment;

    if (_paymentMethod == 'card') {
      title = 'Secure Card Payment';
      details = 'Total Amount: PKR ${context.read<CartProvider>().totalPrice.toStringAsFixed(0)}\n\nPlease use our secure gateway link below to pay, then enter your Transaction ID.';
      color = SColors.catBlue;
      icon = Icons.credit_card;
    } else if (_paymentMethod == 'bank') {
      title = 'Bank Transfer';
      details = 'Bank: Meezan Bank Limited\nAcc: 09260107302530\nTitle: Saith Commission Shop\nBranch: Wahndo';
      color = SColors.catIndigo;
      icon = Icons.account_balance;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: SRadius.radiusXs),
            ),
            const SizedBox(height: 24),
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: SRadius.radiusMd, border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Text(details, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
            if (_paymentMethod == 'card') ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {}, // Integrate actual link here
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Payment Gateway'),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Transaction ID / Reference No.',
                hintText: 'Enter the confirmation code',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: const OutlineInputBorder(borderRadius: SRadius.radiusMd),
              ),
              onChanged: (v) => _transactionId = v,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_transactionId.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please enter Transaction ID')));
                  return;
                }
                Navigator.pop(ctx);
                _placeOrder();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
              ),
              child: const Text('Confirm Payment & Place Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String invoiceNo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: SRadius.radiusLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: SColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const ResponsiveText('Order Confirmed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ResponsiveText('Invoice: $invoiceNo', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            const Text(
              'Thank you for your business. We have received your order and payment details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment Status:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(_paymentMethod == 'credit' ? 'PENDING' : 'VERIFYING',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: _paymentMethod == 'credit' ? SColors.warning : SColors.catBlue)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/customer-home', (_) => false);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: SColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
              ),
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Delivery Section
                _SectionCard(
                  title: 'Delivery Details',
                  icon: Icons.local_shipping_outlined,
                  child: Column(
                    children: [
                      _buildTextField(_nameCtrl, 'Full Name', Icons.person_outline, required: true),
                      const SizedBox(height: 12),
                      _buildTextField(_addressCtrl, 'Delivery Address', Icons.location_on_outlined, maxLines: 2),
                      const SizedBox(height: 12),
                      _buildTextField(_phoneCtrl, 'Mobile Number', Icons.phone_outlined, type: TextInputType.phone, required: true),
                      const SizedBox(height: 12),
                      _buildTextField(_notesCtrl, 'Order Notes (Optional)', Icons.note_alt_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Section
                _SectionCard(
                  title: 'Payment Method',
                  icon: Icons.payment_outlined,
                  child: Column(
                    children: _paymentMethods.map((m) {
                      final id = m['id'] as String;
                      final label = m['en'] as String;
                      final icon = m['icon'] as IconData;
                      final color = m['color'] as Color;
                      final isSelected = _paymentMethod == id;

                      return InkWell(
                        onTap: () => setState(() => _paymentMethod = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: SRadius.radiusMd,
                            border: Border.all(color: isSelected ? color : SColors.textTertiary, width: isSelected ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: isSelected ? color : Colors.grey, size: 22),
                              const SizedBox(width: 12),
                              Expanded(child: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87))),
                              if (isSelected) Icon(Icons.check_circle, color: color, size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Summary Section
                _SectionCard(
                  title: 'Order Summary',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      ...cart.items.map((item) {
                        final pricePerKg = item.pricePer40kg / 40;
                        final pricePer50kg = pricePerKg * 50;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ResponsiveText(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('${item.quantity.toStringAsFixed(0)} x PKR ${pricePer50kg.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('PKR ${item.totalPrice.toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('PKR ${cart.totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool required = false, TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: SRadius.radiusMd),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: ElevatedButton(
        onPressed: _isPlacing ? null : _placeOrder,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
        ),
        child: _isPlacing
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Placing Order...'),
          ],
        )
            : const Text('Confirm & Place Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: SRadius.radiusLg),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: SColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const Divider(height: 20),
        child,
      ]),
    ),
  );
}
