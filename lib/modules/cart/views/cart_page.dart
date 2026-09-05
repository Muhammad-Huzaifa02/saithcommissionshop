import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/cart/providers/cart_provider.dart';
import 'package:saithcommissionshop/data/models/invoice_models.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';


class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Shopping Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _showClearDialog(context),
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyState(context)
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];
                return _buildCartItem(context, item, i);
              },
            ),
          ),
          _buildBottomBar(context, cart),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: SColors.textTertiary),
          const SizedBox(height: 20),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Browse products and add them to your cart', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/customer-home'),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCartItem(BuildContext context, InvoiceProduct item, int index) {
    final pricePerKg = item.pricePer40kg / 40;
    final pricePer50kg = pricePerKg * 50;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: SRadius.radiusLg),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: SColors.primary.withValues(alpha: 0.1),
                borderRadius: SRadius.radiusMd,
              ),
              child: Icon(Icons.grain, color: SColors.primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('PKR ${pricePer50kg.toStringAsFixed(0)} per 50kg bag', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    'Total: PKR ${item.totalPrice.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: SColors.primary, fontSize: 14),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _QtyBtn(icon: Icons.remove, onTap: () => context.read<CartProvider>().decreaseQty(index)),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  alignment: Alignment.center,
                  child: Text(item.quantity.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                _QtyBtn(icon: Icons.add, onTap: () => context.read<CartProvider>().increaseQty(index)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(SRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cart.itemCount} items', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total Amount', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('PKR ${cart.totalPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: SColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/checkout'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: SColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: SRadius.radiusLg),
              elevation: 0,
            ),
            child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: SColors.error, foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: SRadius.radiusSm,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: SColors.primary.withValues(alpha: 0.1),
        borderRadius: SRadius.radiusSm,
      ),
      child: Icon(icon, size: 18, color: SColors.primary),
    ),
  );
}
