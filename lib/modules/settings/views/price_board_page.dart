// ============================================================
// lib/pages/price_board_page.dart
// Live rice price board — mandi-style display
// Reads from ProductProvider (already in your project)
// Route: '/price-board'
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class PriceBoardPage extends StatefulWidget {
  /// isAdmin: show edit buttons; false = customer read-only view
  final bool isAdmin;
  const PriceBoardPage({super.key, this.isAdmin = false});

  @override
  State<PriceBoardPage> createState() => _PriceBoardPageState();
}

class _PriceBoardPageState extends State<PriceBoardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Subtle pulse for "live" feel
    _ticker = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final products = pp.products
        .where((p) =>
            p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: SColors.background,
      body: CustomScrollView(slivers: [
        // ── App bar ──────────────────────────────────────────
        SliverAppBar(
          automaticallyImplyLeading: false,
          expandedHeight: 140,
          pinned: true,
          backgroundColor: SColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(gradient: SGradient.primary),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      SSpacing.md, SSpacing.sm, SSpacing.md, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const BackButton(color: Colors.white),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Price Board',
                                  style: SText.headingLg.copyWith(
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        // Live indicator
                        AnimatedBuilder(
                          animation: _ticker,
                          builder: (_, __) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: SSpacing.sm, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: 0.10 + _ticker.value * 0.08),
                              borderRadius: SRadius.radiusFull,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.5),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: SColors.primaryXLight,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(
                                    color: SColors.primaryXLight.withValues(
                                        alpha: 0.5 + _ticker.value * 0.5),
                                    blurRadius: 4,
                                  )],
                                ),
                              ),
                              const SizedBox(width: SSpacing.xs),
                              Text('LIVE',
                                  style: SText.labelXs.copyWith(
                                      color: Colors.white)),
                            ]),
                          ),
                        ),
                      ]),
                      const SizedBox(height: SSpacing.sm),
                      Text(
                        'Updated ${now.day}/${now.month}/${now.year} '
                        '${now.hour.toString().padLeft(2, '0')}:'
                        '${now.minute.toString().padLeft(2, '0')}',
                        style: SText.labelXs.copyWith(
                            color: SColors.textOnDarkSub),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Search bar ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(SSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              style: SText.bodyMd.copyWith(color: SColors.textPrimary),
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search rice variety...',
                hintStyle: SText.bodyMd.copyWith(color: SColors.textTertiary),
                prefixIcon: const Icon(Icons.search,
                    color: SColors.textSecondary, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: SColors.textTertiary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: SColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: SSpacing.md,
                    vertical: SSpacing.sm + SSpacing.xs),
                border: OutlineInputBorder(
                    borderRadius: SRadius.radiusMd,
                    borderSide: const BorderSide(
                        color: SColors.border, width: 0.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: SRadius.radiusMd,
                    borderSide: const BorderSide(
                        color: SColors.border, width: 0.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: SRadius.radiusMd,
                    borderSide: const BorderSide(
                        color: SColors.primary, width: 1.5)),
              ),
            ),
          ),
        ),

        // ── Summary strip ────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                SSpacing.md, 0, SSpacing.md, SSpacing.md),
            child: Row(children: [
              _SummaryChip(
                '${products.length} varieties',
                Icons.grain,
                SColors.primary,
              ),
              const SizedBox(width: SSpacing.sm),
              _SummaryChip(
                '${products.where((p) => !p.isOutOfStock).length} available',
                Icons.check_circle_outline,
                SColors.success,
              ),
              const SizedBox(width: SSpacing.sm),
              _SummaryChip(
                '${products.where((p) => p.isOutOfStock).length} out',
                Icons.do_not_disturb_alt_outlined,
                SColors.error,
              ),
            ]),
          ),
        ),

        // ── Price list ───────────────────────────────────────
        products.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Text('No products found',
                      style: SText.bodyMd.copyWith(
                          color: SColors.textTertiary)),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    SSpacing.md, 0, SSpacing.md, SSpacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: SSpacing.sm),
                      child: _PriceCard(
                        product: products[i],
                        isAdmin: widget.isAdmin,
                        onEditTap: () =>
                            _showEditSheet(context, products[i]),
                      ),
                    ),
                    childCount: products.length,
                  ),
                ),
              ),
      ]),

      // Admin: FAB to add product
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin-products'),
              backgroundColor: SColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Product',
                  style: SText.labelLg.copyWith(color: Colors.white)),
            )
          : null,
    );
  }

  void _showEditSheet(BuildContext ctx, dynamic product) {
    final priceCtrl = TextEditingController(
        text: product.pricePer40kg.toStringAsFixed(0));
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: SColors.surface,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(SRadius.xl)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: SColors.border,
                    borderRadius: SRadius.radiusFull),
              )),
              const SizedBox(height: SSpacing.md),
              Text('Update Price — ${product.name}',
                  style: SText.headingMd.copyWith(
                      color: SColors.textPrimary)),
              const SizedBox(height: SSpacing.lg),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: SText.amountLg.copyWith(
                    color: SColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Price per 40 kg (PKR)',
                  prefixText: 'PKR  ',
                  prefixStyle: SText.labelLg.copyWith(
                      color: SColors.textSecondary),
                  filled: true,
                  fillColor: SColors.surfaceAlt,
                  border: OutlineInputBorder(
                      borderRadius: SRadius.radiusMd,
                      borderSide: const BorderSide(
                          color: SColors.border, width: 0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: SRadius.radiusMd,
                      borderSide: const BorderSide(
                          color: SColors.border, width: 0.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: SRadius.radiusMd,
                      borderSide: const BorderSide(
                          color: SColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: SSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final price = double.tryParse(priceCtrl.text);
                    if (price == null || price <= 0) return;
                    await ctx.read<ProductProvider>()
                        .updatePrice(product.id, price);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: SRadius.radiusMd),
                  ),
                  child: Text('Update Price',
                      style: SText.labelLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: SSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price card ────────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final dynamic product;
  final bool isAdmin;
  final VoidCallback onEditTap;
  const _PriceCard({
    required this.product,
    required this.isAdmin,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final p          = product;
    final isOut      = p.isOutOfStock as bool;
    final isLow      = p.isLowStock   as bool;
    final statusColor = isOut ? SColors.error
        : isLow  ? SColors.warning
        : SColors.success;
    final statusLabel = isOut ? 'Out of Stock'
        : isLow  ? 'Low Stock'
        : 'Available';

    return Container(
      padding: SSpacing.cardPadding,
      decoration: BoxDecoration(
        color: SColors.surface,
        borderRadius: SRadius.radiusMd,
        border: Border.all(
          color: isOut
              ? SColors.error.withValues(alpha: 0.3)
              : SColors.border,
          width: isOut ? 1 : 0.5,
        ),
        boxShadow: SShadow.card,
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: SRadius.radiusMd,
          ),
          child: Icon(Icons.grain,
              color: statusColor, size: 24),
        ),
        const SizedBox(width: SSpacing.md),

        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(p.name as String,
                    style: SText.headingSm.copyWith(
                        color: SColors.textPrimary)),
              ),
              SStatusBadge(status: isOut ? 'overdue'
                  : isLow ? 'pending' : 'paid',
                label: statusLabel),
            ]),
            const SizedBox(height: SSpacing.xs),
            // Price row — main highlight
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                'PKR ${(p.pricePer40kg as double).toStringAsFixed(0)}',
                style: SText.amountMd.copyWith(
                    color: SColors.textPrimary),
              ),
              const SizedBox(width: SSpacing.xs),
              Text('/ 40 kg',
                  style: SText.bodyXs.copyWith(
                      color: SColors.textSecondary)),
            ]),
            const SizedBox(height: 2),
            Text(
              '${(p.availableStockKg as double).toStringAsFixed(0)} kg · '
              '${(p.stockBags as double).toStringAsFixed(0)} bags in stock',
              style: SText.bodyXs.copyWith(
                  color: SColors.textSecondary),
            ),
          ],
        )),

        if (isAdmin) ...[
          const SizedBox(width: SSpacing.sm),
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: SColors.primaryBg,
                borderRadius: SRadius.radiusSm,
              ),
              child: const Icon(Icons.edit_outlined,
                  color: SColors.primary, size: 16),
            ),
          ),
        ],
      ]),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SummaryChip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SSpacing.sm, vertical: SSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: SRadius.radiusFull,
        border: Border.all(
            color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label, style: SText.labelXs.copyWith(color: color)),
      ]),
    );
  }
}
