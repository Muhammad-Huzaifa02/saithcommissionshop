import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';
import 'package:saithcommissionshop/data/repositories/invoice_transaction_service.dart';
import 'package:saithcommissionshop/data/services/invoice_validation_service.dart';
import 'package:saithcommissionshop/modules/scanner/views/invoice_scanner_page.dart';

class AdminManualInvoicePage extends StatefulWidget {
  const AdminManualInvoicePage({super.key});

  @override
  State<AdminManualInvoicePage> createState() => _AdminManualInvoicePageState();
}

class _AdminManualInvoicePageState extends State<AdminManualInvoicePage> {
  final List<InvoiceProduct> products = [];
  final _formKey = GlobalKey<FormState>();

  final _customerIdCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedCustomerUid;

  @override
  void initState() {
    super.initState();
    _customerPhoneCtrl.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = _customerPhoneCtrl.text.trim();
    if (phone.length >= 11) {
      final cp = context.read<CustomerProvider>();
      final customers = cp.customers;
      try {
        final existing = customers.firstWhere((c) => c.phone == phone);
        if (_customerNameCtrl.text.isEmpty) {
          _customerNameCtrl.text = existing.name;
        }
        _customerIdCtrl.text = existing.customerId;
        _selectedCustomerUid = existing.id;
      } catch (_) {
        // Not found, generate a new one if empty
        if (_customerIdCtrl.text.isEmpty || _customerIdCtrl.text.startsWith('CUST-')) {
           _customerIdCtrl.text = cp.nextCustomerId;
           _selectedCustomerUid = null;
        }
      }
    }
  }

  double commissionPercent = 0, fixedCommission = 0;
  double laborCharges = 0, packingCharges = 0, transportCharges = 0, otherCharges = 0;
  double discountPercent = 0, manualDiscount = 0, gstPercent = 0, amountPaid = 0;
  String paymentMethod = 'cash';

  @override
  void dispose() {
    _customerIdCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  InvoiceData get _currentInvoice {
    final ip = context.read<InvoiceProvider>();
    final cp = context.read<CustomerProvider>();
    final dispId = _customerIdCtrl.text.isEmpty ? cp.nextCustomerId : _customerIdCtrl.text;
    final technicalId = _selectedCustomerUid ?? dispId;
    
    return InvoiceData(
      invoiceNo: ip.nextInvoiceNo,
      customerId: technicalId,
      customerDisplayId: dispId,
      customerName: _customerNameCtrl.text,
      customerPhone: _customerPhoneCtrl.text,
      dateTime: DateTime.now(),
      products: products,
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
    notes: _notesCtrl.text,
    paymentMethod: paymentMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = InvoiceCalculationService.calculate(_currentInvoice);

    return AppPageScaffold(
      title: 'New Invoice',
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSection('Customer Info', Icons.person, [
              _buildTextField(_customerNameCtrl, 'Customer Name *', 'Enter name', Icons.person_outline, required: true),
              const SizedBox(height: 12),
              _buildTextField(_customerPhoneCtrl, 'Mobile Number *', '03001234567', Icons.phone_outlined, required: true, type: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(_customerIdCtrl, 'Customer ID (Optional)', 'Enter ID', Icons.badge_outlined),
            ]),
            const SizedBox(height: 16),

            _buildSection('Products', Icons.inventory_2, [
              if (products.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SColors.background,
                    borderRadius: SRadius.radiusMd,
                    border: Border.all(color: SColors.border),
                  ),
                  child: const Center(
                    child: Text('No product added',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductRow(
                    index: i,
                    product: products[i],
                    onChanged: (p) => setState(() => products[i] = p),
                    onDelete: () => setState(() => products.removeAt(i)),
                    availableProducts: context.read<ProductProvider>().products,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                      onPressed: _addProduct,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Product'),
                      onPressed: _scanProduct,
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 16),

            _buildSection('Charges', Icons.calculate, [
              Row(children: [
                Expanded(child: _numField('Labor', 'Enter labor charges', (v) => setState(() => laborCharges = v))),
                const SizedBox(width: 12),
                Expanded(child: _numField('Packing', 'Enter packing charges', (v) => setState(() => packingCharges = v))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numField('Transport', 'Enter transport charges', (v) => setState(() => transportCharges = v))),
                const SizedBox(width: 12),
                Expanded(child: _numField('Other', 'Enter other charges', (v) => setState(() => otherCharges = v))),
              ]),
            ]),
            const SizedBox(height: 16),

            _buildSection('Commission & Discount', Icons.percent, [
              Row(children: [
                Expanded(child: _numField('Commission %', '0.0', (v) => setState(() => commissionPercent = v))),
                const SizedBox(width: 12),
                Expanded(child: _numField('Fixed Commission', '0.0', (v) => setState(() => fixedCommission = v))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numField('Discount %', '0.0', (v) => setState(() => discountPercent = v))),
                const SizedBox(width: 12),
                Expanded(child: _numField('Manual Discount', '0.0', (v) => setState(() => manualDiscount = v))),
              ]),
              const SizedBox(height: 12),
              _numField('GST %', '0.0', (v) => setState(() => gstPercent = v)),
            ]),
            const SizedBox(height: 16),

            _buildSection('Payment', Icons.payments, [
              _numField('Amount Paid (PKR)', '0.0', (v) => setState(() => amountPaid = v)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit')),
                ],
                onChanged: (v) => setState(() => paymentMethod = v!),
              ),
              const SizedBox(height: 12),
              _buildTextField(_notesCtrl, 'Notes (Optional)', 'Enter notes', Icons.notes, maxLines: 2),
            ]),
            const SizedBox(height: 16),

            // Summary Card
            _buildSummaryCard(totals),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Invoice'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _saveInvoice,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: SColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: ResponsiveText(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, IconData icon,
      {bool required = false, TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _numField(String label, String hint, Function(double) onChanged) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint, prefixText: 'PKR '),
      onChanged: (v) => setState(() => onChanged(double.tryParse(v) ?? 0)),
    );
  }

  Widget _buildSummaryCard(InvoiceTotals totals) {
    return Card(
      color: SColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Summary',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(color: Colors.white30),
            _summaryRow('Products Total', totals.productsTotal),
            _summaryRow('Commission', totals.commission),
            _summaryRow('Expenses', totals.totalExpenses),
            _summaryRow('Discount', -totals.discountAmount),
            _summaryRow('GST', totals.gstAmount),
            const Divider(color: Colors.white54),
            _summaryRow('Grand Total', totals.grandTotal, bold: true, big: true),
            _summaryRow('Paid', amountPaid),
            _summaryRow('Pending', totals.pendingAmount,
                color: totals.pendingAmount > 0 ? SColors.warning : SColors.success),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false, bool big = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: TextStyle(
              color: SColors.textOnDarkSub,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: big ? 16 : 13,
            )),
          ),
          const SizedBox(width: 8),
          FittedBox(
            child: Text(
              'PKR ${value.toStringAsFixed(0)}',
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: big ? 18 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addProduct() {
    final productsList = context.read<ProductProvider>().products;
    if (productsList.isEmpty) {
      setState(() => products.add(const InvoiceProduct(name: '', pricePer40kg: 0)));
      return;
    }
    setState(() => products.add(InvoiceProduct(
      name: productsList.first.name,
      productId: productsList.first.id,
      pricePer40kg: productsList.first.pricePer40kg,
    )));
  }

  void _scanProduct() async {
    final result = await Navigator.push<InvoiceProduct>(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceScannerPage(
          onProductScanned: (product) {
            setState(() => products.add(product));
          },
        ),
      ),
    );

    // If popped with result (fallback)
    if (result != null) {
      setState(() => products.add(result));
    }
  }

  Future<void> _saveInvoice() async {
    if (_customerNameCtrl.text.isEmpty || _customerPhoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer info is required'), backgroundColor: SColors.error),
      );
      return;
    }
    if (!InvoiceValidationService.isValidPakistaniPhone(_customerPhoneCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid phone number (e.g. 03XXXXXXXXX) — invoices are sent via WhatsApp/SMS'), backgroundColor: SColors.error),
      );
      return;
    }
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product'), backgroundColor: SColors.error),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await InvoiceTransactionService.saveInvoice(
        invoice: _currentInvoice,
        invoiceProvider: context.read<InvoiceProvider>(),
        productProvider: context.read<ProductProvider>(),
        ledgerProvider: context.read<LedgerProvider>(),
      );

      if (!mounted || !context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully ✓'), backgroundColor: SColors.success),
      );
      Navigator.pop(context); // Return to previous page
    } catch (e) {
      if (!mounted || !context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save invoice: $e'), backgroundColor: SColors.error),
      );
    }
  }
}

class _ProductRow extends StatelessWidget {
  final int index;
  final InvoiceProduct product;
  final Function(InvoiceProduct) onChanged;
  final VoidCallback onDelete;
  final List<Product> availableProducts;

  const _ProductRow({
    required this.index, required this.product,
    required this.onChanged, required this.onDelete, required this.availableProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SColors.successBg,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: availableProducts.isNotEmpty
                      ? DropdownButtonFormField<String>(
                    initialValue: availableProducts.any((p) => p.name == product.name)
                        ? product.name : (availableProducts.isNotEmpty ? availableProducts.first.name : null),
                    decoration: const InputDecoration(labelText: 'Product', isDense: true),
                    items: availableProducts.map<DropdownMenuItem<String>>((p) =>
                        DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      final p = availableProducts.firstWhere((pr) => pr.name == v);
                      onChanged(product.copyWith(name: v, productId: p.id, pricePer40kg: p.pricePer40kg));
                    },
                  )
                      : TextFormField(
                    initialValue: product.name,
                    decoration: const InputDecoration(labelText: 'Product Name', isDense: true),
                    onChanged: (v) => onChanged(product.copyWith(name: v)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: Icon(Icons.delete, color: SColors.error), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Quantities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: product.bags50 == 0 ? '' : product.bags50.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '50kg Bags', isDense: true),
                    onChanged: (v) => onChanged(product.copyWith(bags50: int.tryParse(v) ?? 0)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: product.bags100 == 0 ? '' : product.bags100.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '100kg Bags', isDense: true),
                    onChanged: (v) => onChanged(product.copyWith(bags100: int.tryParse(v) ?? 0)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: product.looseWeightKg == 0 ? '' : product.looseWeightKg.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Loose kgs', isDense: true),
                    onChanged: (v) => onChanged(product.copyWith(looseWeightKg: double.tryParse(v) ?? 0)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: product.pricePer40kg.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price / 40kg', prefixText: 'PKR ', isDense: true),
                    onChanged: (v) => onChanged(product.copyWith(pricePer40kg: double.tryParse(v) ?? 0)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: PKR ${product.totalPrice.toStringAsFixed(0)} | ${product.totalWeightKg.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

