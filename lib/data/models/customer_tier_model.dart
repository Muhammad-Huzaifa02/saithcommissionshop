import 'package:flutter/material.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

enum CustomerTier { retail, wholesale, vip }

extension CustomerTierExt on CustomerTier {
  String get label => switch (this) {
    CustomerTier.retail    => 'Retail',
    CustomerTier.wholesale => 'Wholesale',
    CustomerTier.vip       => 'VIP',
  };

  double get discountRate => switch (this) {
    CustomerTier.retail    => 0.0,
    CustomerTier.wholesale => 0.05,   // 5% off
    CustomerTier.vip       => 0.10,   // 10% off
  };

  Color get color => switch (this) {
    CustomerTier.retail    => SColors.textSecondary,
    CustomerTier.wholesale => SColors.catBlue,
    CustomerTier.vip       => SColors.catPurple,
  };

  IconData get icon => switch (this) {
    CustomerTier.retail    => Icons.person_outline,
    CustomerTier.wholesale => Icons.storefront_outlined,
    CustomerTier.vip       => Icons.workspace_premium,
  };
}

// ── Widget: tier-aware price display ─────────────────────────
class TierPriceWidget extends StatelessWidget {
  final double   basePrice;
  final CustomerTier tier;
  const TierPriceWidget({
    super.key,
    required this.basePrice,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final discount     = basePrice * tier.discountRate;
    final finalPrice   = basePrice - discount;
    final hasDiscount  = discount > 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (hasDiscount)
        Text(
          'PKR ${basePrice.toStringAsFixed(0)}',
          style: SText.bodyXs.copyWith(
            color: SColors.textTertiary,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(tier.icon, color: tier.color, size: 14),
        const SizedBox(width: 4),
        Text(
          'PKR ${finalPrice.toStringAsFixed(0)}',
          style: SText.amountSm.copyWith(color: SColors.textPrimary),
        ),
      ]),
      if (hasDiscount)
        Text(
          '${(tier.discountRate * 100).toStringAsFixed(0)}% ${tier.label} discount',
          style: SText.labelXs.copyWith(color: tier.color),
        ),
    ]);
  }
}

// ── Helper: calculate tiered price ───────────────────────────
double calcTieredPrice(double basePrice, CustomerTier tier) =>
    basePrice * (1 - tier.discountRate);

// ── Widget: tier selector (use inside invoice creation) ───────
class TierSelector extends StatelessWidget {
  final CustomerTier selected;
  final ValueChanged<CustomerTier> onChanged;
  const TierSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SSectionHeader(title: 'Customer Tier',
          padding: const EdgeInsets.only(bottom: SSpacing.sm)),
      Row(children: CustomerTier.values.map((tier) {
        final active = tier == selected;
        return Expanded(child: GestureDetector(
          onTap: () => onChanged(tier),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: SSpacing.xs),
            padding: const EdgeInsets.symmetric(
                vertical: SSpacing.sm + SSpacing.xs),
            decoration: BoxDecoration(
              color: active
                  ? tier.color.withValues(alpha: 0.12)
                  : SColors.surfaceAlt,
              borderRadius: SRadius.radiusMd,
              border: Border.all(
                color: active ? tier.color : SColors.border,
                width: active ? 1.5 : 0.5,
              ),
            ),
            child: Column(children: [
              Icon(tier.icon,
                  color: active ? tier.color : SColors.textTertiary,
                  size: 20),
              const SizedBox(height: SSpacing.xs),
              Text(tier.label,
                  style: SText.labelSm.copyWith(
                    color: active ? tier.color : SColors.textSecondary,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                  )),
              if (tier.discountRate > 0)
                Text(
                  '-${(tier.discountRate * 100).toStringAsFixed(0)}%',
                  style: SText.labelXs.copyWith(
                      color: active ? tier.color : SColors.textTertiary),
                ),
            ]),
          ),
        ));
      }).toList()),
    ]);
  }
}
