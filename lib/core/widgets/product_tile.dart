import 'package:flutter/material.dart';
import 'package:saithcommissionshop/data/models/product_model.dart';
import 'package:saithcommissionshop/core/utils/utils.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool showStock;

  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.showStock = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLow = product.availableStockKg < 200;
    final isOut = product.isOutOfStock;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge — nullable-safe
              if (product.category != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.category!,
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 8),

              // Price
              Text(
                PakistanFormatter.formatPKR(product.pricePer40kg),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary),
              ),
              Text('Per 40kg',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade500)),

              if (showStock) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isOut
                          ? Icons.cancel
                          : isLow
                          ? Icons.warning_amber
                          : Icons.check_circle,
                      size: 14,
                      color: isOut
                          ? Colors.red
                          : isLow
                          ? Colors.orange
                          : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOut
                          ? 'Out of Stock'
                          : '${product.stockBags.toStringAsFixed(0)} Bags',
                      style: TextStyle(
                          fontSize: 11,
                          color: isOut
                              ? Colors.red
                              : isLow
                              ? Colors.orange
                              : Colors.grey.shade600),
                    ),
                  ],
                ),
              ],

              if (onAddToCart != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isOut ? null : onAddToCart,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add to Cart',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}