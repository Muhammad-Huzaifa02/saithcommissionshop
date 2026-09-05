import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/suppliers/providers/supplier_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/purchase/providers/purchase_provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/data/models/purchase_model.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/core/utils/overflow_handler.dart';

class AdminPurchasePage extends StatefulWidget {
  const AdminPurchasePage({super.key});
  @override
  State<AdminPurchasePage> createState() => _AdminPurchasePageState();
}

class _AdminPurchasePageState extends State<AdminPurchasePage> {
  String? _selectedSupplierId;
  final List<PurchaseProduct> _items = [];
  final _amountPaidCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().products;

    double total = _items.fold(0, (s, i) => s + i.totalCost);

    return AppPageScaffold(
      title: 'Purchase Order',
      body: Column(
        children: [
          // Supplier Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedSupplierId,
            decoration: const InputDecoration(labelText: 'Supplier'),
            items: suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => _selectedSupplierId = v),
          ),
          const SizedBox(height: 20),

          // Items List
          const Text('Purchase Items', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._items.map((item) => ListTile(
            title: ResponsiveText(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item.bags} bags x PKR ${item.purchasePricePer40kg}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PKR ${item.totalCost}'),
                IconButton(
                  icon: Icon(Icons.delete, color: SColors.error),
                  onPressed: () => setState(() => _items.remove(item)),
                ),
              ],
            ),
          )),
          ElevatedButton.icon(
            onPressed: () => _showAddItemDialog(context, products),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const Divider(height: 32),

          // Totals
          Text('Total: PKR $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountPaidCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount Paid'),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _items.isEmpty || _selectedSupplierId == null ? null : _saveOrder,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Save Purchase Order'),
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, List<Product> products) {
    String? prodId;
    final bagsCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              items: products.map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.name))).toList(),
              onChanged: (v) => prodId = v,
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            TextField(controller: bagsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bags')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Purchase Price/40kg')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (prodId != null) {
              final p = products.firstWhere((p) => p.id == prodId);
              final bags = double.tryParse(bagsCtrl.text) ?? 0;
              final price = double.tryParse(priceCtrl.text) ?? 0;
              setState(() {
                _items.add(PurchaseProduct(
                  productId: prodId!,
                  name: p.name,
                  bags: bags,
                  purchasePricePer40kg: price,
                  totalCost: bags * price,
                ));
              });
            }
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _saveOrder() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final purchaseProvider = context.read<PurchaseProvider>();
    final supplierProvider = context.read<SupplierProvider>();
    final adminId = context.read<AdminUserProvider>().currentUser?.id ?? 'unknown-admin';

    final sup = supplierProvider.suppliers.firstWhere((s) => s.id == _selectedSupplierId);
    final order = PurchaseOrder(
      id: '',
      supplierId: sup.id,
      supplierName: sup.name,
      date: DateTime.now(),
      products: List.from(_items),
      totalAmount: _items.fold(0, (s, i) => s + i.totalCost),
      amountPaid: double.tryParse(_amountPaidCtrl.text) ?? 0,
      paymentMethod: 'cash',
    );

    try {
      // Atomic: the purchase record and every item's stock increment,
      // price update, and history entry either all succeed or all fail
      // together — no more risk of a purchase being logged with only
      // some items' stock actually applied.
      await purchaseProvider.addPurchaseOrderWithStock(order: order, adminId: adminId);
      if (!context.mounted) return;

      navigator.pop();
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Purchase Saved & Stock Updated')));
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}


