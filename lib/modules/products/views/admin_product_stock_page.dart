import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';

class AdminProductStockPage extends StatelessWidget {
  const AdminProductStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return AppPageScaffold(
      title: 'Stock',
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.products.length,
        itemBuilder: (_, i) {
          final p = provider.products[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ResponsiveText(p.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(p.isOutOfStock ? 'Empty' : p.isLowStock ? 'Low' : 'OK',
                            style: const TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: p.isOutOfStock ? SColors.error : p.isLowStock ? SColors.warning : SColors.success,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (p.availableStockKg / 2000).clamp(0.0, 1.0),
                    backgroundColor: SColors.border,
                    valueColor: AlwaysStoppedAnimation(p.isLowStock ? SColors.error : SColors.success),
                    borderRadius: SRadius.radiusXs,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${p.availableStockKg.toStringAsFixed(0)} kg (${p.stockBags.toStringAsFixed(0)} bags)',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('PKR ${p.pricePer40kg.toStringAsFixed(0)}/40kg',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SafeRow(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 2,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Stock', style: TextStyle(fontSize: 12)),
                          onPressed: () => _addStock(context, p),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 2,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Price', style: TextStyle(fontSize: 12)),
                          onPressed: () => _editPrice(context, p),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _addStock(BuildContext context, dynamic p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Stock: ${p.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Kilograms', suffixText: 'kg'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            final kg = double.tryParse(ctrl.text) ?? 0;
            if (kg > 0) {
              final adminId = context.read<AdminUserProvider>().currentUser?.id ?? 'unknown-admin';
              context.read<ProductProvider>().addStock(
                productId: p.id, addedKg: kg,
                reference: 'MANUAL-${DateTime.now().millisecondsSinceEpoch}', adminId: adminId,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${kg.toStringAsFixed(0)} kg added ✓'), backgroundColor: SColors.success));
            }
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _editPrice(BuildContext context, dynamic p) {
    final ctrl = TextEditingController(text: p.pricePer40kg.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Price: ${p.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Price (40kg)', prefixText: 'PKR '),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            final price = double.tryParse(ctrl.text);
            if (price != null) {
              context.read<ProductProvider>().updateProduct(p.id, p.copyWith(pricePer40kg: price));
              Navigator.pop(ctx);
            }
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
