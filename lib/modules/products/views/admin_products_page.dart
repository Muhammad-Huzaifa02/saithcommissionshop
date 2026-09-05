import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/data/models/admin_user_model.dart';
import 'package:saithcommissionshop/data/services/permission_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});
  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  String _search   = '';
  String _category = 'all';

  static const _categories = ['all', 'Basmati', 'Kernel', 'Sella', 'IRRI', 'Other'];

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<ProductProvider>();
    final admin     = context.watch<AdminUserProvider>().currentUser;
    final canEdit   = PermissionService.hasPermission(
        admin?.role ?? AdminRole.staff, 'manage_products');

    final filtered  = provider.products.where((p) {
      final matchSearch   = p.name.toLowerCase().contains(_search.toLowerCase());
      final matchCategory = _category == 'all' || (p.category ?? '') == _category;
      return matchSearch && matchCategory;
    }).toList();

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Products (${provider.products.length})'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _showProductDialog(context),
              tooltip: 'Add Product',
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats strip ──────────────────────────────────────
          Container(
            color: SColors.primaryLight,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat('Total', '${provider.products.length}', Colors.white),
                _Stat('Healthy', '${provider.healthyCount}', Colors.greenAccent),
                _Stat('Low', '${provider.lowStockCount}', Colors.orangeAccent),
                _Stat('Out', '${provider.outOfStockCount}', Colors.redAccent),
                _Stat('Value', Fmt.currency(provider.totalStockValue), Colors.white),
              ],
            ),
          ),

          // ── Search + filter ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: SColors.primary),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _search = ''))
                    : null,
                filled: true, fillColor: SColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: const OutlineInputBorder(
                    borderRadius: SRadius.radiusMd, borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Category chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final sel = _category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? SColors.primary : SColors.surface,
                        borderRadius: SRadius.radiusLg,
                        border: Border.all(
                            color: sel ? SColors.primary : SColors.border),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            color: sel ? Colors.black : SText.bodyMd.color,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: provider.products.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: SColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  const Text('No products yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (canEdit)
                    ElevatedButton.icon(
                      onPressed: () => _showProductDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Product'),
                    ),
                ],
              ),
            )
                : filtered.isEmpty
                ? const Center(child: Text('No products match your search',
                style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _ProductCard(
                product: filtered[i],
                canEdit: canEdit,
                onEdit:  () => _showProductDialog(context, product: filtered[i]),
                onAddStock: () => _showAddStockDialog(context, filtered[i]),
                onDelete: canEdit
                    ? () => _confirmDelete(context, filtered[i])
                    : null,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      )
          : null,
    );
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    final isEdit      = product != null;
    final nameCtrl    = TextEditingController(text: product?.name ?? '');
    final priceCtrl   = TextEditingController(
        text: product != null ? product.pricePer40kg.toStringAsFixed(0) : '');
    final stockCtrl   = TextEditingController(
        text: product != null ? product.availableStockKg.toStringAsFixed(0) : '');
    final reorderCtrl = TextEditingController(
        text: product != null ? product.reorderPointKg.toStringAsFixed(0) : '200');
    String category   = product?.category ?? 'Basmati';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: SColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SRadius.xl)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: const BoxDecoration(
                    color: SColors.textTertiary,
                    borderRadius: SRadius.radiusXs),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Icon(isEdit ? Icons.edit_outlined : Icons.add_circle_outline,
                      color: SColors.primary),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              ),
              const Divider(height: 0.5, thickness: 0.5, color: SColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(children: [
                    _buildField(nameCtrl,   'Product Name *',         Icons.grain,
                        validator: Validators.productName),
                    const SizedBox(height: 14),
                    _buildField(priceCtrl,  'Price per 40kg (PKR) *', Icons.money,
                        keyboard: TextInputType.number,
                        validator: Validators.price),
                    const SizedBox(height: 14),
                    _buildField(stockCtrl,  'Available Stock (kg)',    Icons.inventory_2_outlined,
                        keyboard: TextInputType.number,
                        validator: Validators.stockQty),
                    const SizedBox(height: 14),
                    _buildField(reorderCtrl,'Reorder Point (kg)',      Icons.warning_outlined,
                        keyboard: TextInputType.number,
                        helperText: 'Alert when stock falls below this'),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                            borderRadius: SRadius.radiusMd),
                      ),
                      items: _categories.skip(1)
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setSheet(() => category = v!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final sm = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          final prov = context.read<ProductProvider>();

                          // Validate
                          final nameErr  = Validators.productName(nameCtrl.text);
                          final priceErr = Validators.price(priceCtrl.text);
                          if (nameErr != null || priceErr != null) {
                            sm.showSnackBar(SnackBar(
                              content: Text(nameErr ?? priceErr!),
                              backgroundColor: SColors.error,
                            ));
                            return;
                          }
                          final name    = SecurityUtils.sanitize(nameCtrl.text.trim());
                          final price   = double.parse(priceCtrl.text);
                          final stock   = double.tryParse(stockCtrl.text)   ?? 0;
                          final reorder = double.tryParse(reorderCtrl.text) ?? 200;

                          if (isEdit) {
                            prov.updateProduct(
                              product.id,
                              product.copyWith(
                                pricePer40kg:     price,
                                availableStockKg: stock,
                                reorderPointKg:   reorder,
                                category:         category,
                              ),
                            );
                          } else {
                            // Check duplicate name
                            final exists = prov.getProductByName(name) != null;
                            if (exists) {
                              sm.showSnackBar(const SnackBar(
                                content: Text('A product with this name already exists'),
                                backgroundColor: SColors.error,
                              ));
                              return;
                            }
                            prov.addProduct(Product(
                              id:               'PROD-${DateTime.now().millisecondsSinceEpoch}',
                              name:             name,
                              pricePer40kg:     price,
                              availableStockKg: stock,
                              category:         category,
                              reorderPointKg:   reorder,
                            ));
                          }
                          nav.pop();
                          sm.showSnackBar(SnackBar(
                            content: Text(isEdit ? 'Product updated' : 'Product added'),
                            backgroundColor: SColors.success,
                          ));
                        },
                        child: Text(isEdit ? 'Save Changes' : 'Add Product',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, Product p) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Stock: ${p.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Current: ${p.availableStockKg.toStringAsFixed(0)} kg  (${p.stockBags.toStringAsFixed(0)} bags)',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Quantity to add (kg)',
              suffixText: 'kg',
              border: OutlineInputBorder(borderRadius: SRadius.radiusMd),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final sm = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final productProv = context.read<ProductProvider>();
              final adminProv = context.read<AdminUserProvider>();

              final err = Validators.stockQty(ctrl.text);
              if (err != null || (double.tryParse(ctrl.text) ?? 0) <= 0) {
                sm.showSnackBar(
                    const SnackBar(content: Text('Enter a valid quantity'),
                        backgroundColor: SColors.error));
                return;
              }
              final kg = double.parse(ctrl.text);
              productProv.addStock(
                productId: p.id,
                addedKg:   kg,
                reference: 'STOCK-${DateTime.now().millisecondsSinceEpoch}',
                adminId:   adminProv.currentUser?.id ?? 'admin',
              );
              nav.pop();
              sm.showSnackBar(SnackBar(
                content: Text('${kg.toStringAsFixed(0)} kg added to ${p.name}'),
                backgroundColor: SColors.success,
              ));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Delete "${p.name}"? This cannot be undone.\n\n'
                'Note: Existing invoices with this product will not be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final sm = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final prov = context.read<ProductProvider>();

              nav.pop();
              prov.deleteProduct(p.id);
              sm.showSnackBar(SnackBar(
                content: Text('${p.name} deleted'),
                backgroundColor: SColors.warning,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: SColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product      product;
  final bool         canEdit;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;
  final VoidCallback? onDelete;

  const _ProductCard({
    required this.product,
    required this.canEdit,
    required this.onEdit,
    required this.onAddStock,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p    = product;
    final clr  = p.isOutOfStock ? SColors.error
        : p.isLowStock   ? SColors.warning
        : SColors.success;
    final pct  = (p.availableStockKg / (p.reorderPointKg * 5)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SRadius.radiusLg,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: clr.withValues(alpha: 0.1),
                    borderRadius: SRadius.radiusMd),
                child: Icon(Icons.grain, color: clr, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(p.category ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: clr.withValues(alpha: 0.1), borderRadius: SRadius.radiusMd),
                child: Text(
                    p.isOutOfStock ? 'Out of Stock'
                        : p.isLowStock ? 'Low Stock'
                        : 'In Stock',
                    style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 12),

            // Price + stock
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _kv('Price / 40kg', 'PKR ${p.pricePer40kg.toStringAsFixed(0)}'),
              _kv('Stock', '${p.availableStockKg.toStringAsFixed(0)} kg'),
              _kv('Bags', p.stockBags.toStringAsFixed(0)),
              _kv('Reorder at', '${p.reorderPointKg.toStringAsFixed(0)} kg'),
            ]),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: SRadius.radiusSm,
              child: LinearProgressIndicator(
                value: pct, minHeight: 8,
                backgroundColor: SColors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(clr),
              ),
            ),

            if (canEdit) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddStock,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Stock'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: SColors.primary,
                        side: const BorderSide(color: SColors.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: SColors.error),
                    tooltip: 'Delete product',
                  ),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    ],
  );
}

// ── Helpers ────────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);
}

Widget _buildField(TextEditingController ctrl, String label, IconData icon, {
  TextInputType keyboard = TextInputType.text,
  String? Function(String?)? validator,
  String? helperText,
}) =>
    TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: SRadius.radiusMd),
        focusedBorder: OutlineInputBorder(
            borderRadius: SRadius.radiusMd,
            borderSide: BorderSide(color: SColors.primary, width: 2)),
      ),
    );
