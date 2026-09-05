import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/data/services/invoice_calculation_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

class AdminProfitDashboardPage extends StatelessWidget {
  const AdminProfitDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ip = context.watch<InvoiceProvider>();
    final pp = context.watch<ProductProvider>();

    // NOTE: revenue here is PRODUCT SALES ONLY (not invoice.grandTotal,
    // which also includes commission and labor/packing/transport/other
    // charges) — it needs to be like-for-like with totalCOGS, which is
    // also computed purely from product weight sold. Using grandTotal
    // here would double-count those charges, since they're then also
    // subtracted below as `expenses`.
    double totalRevenue = 0;
    double totalCommission = 0;
    double totalCOGS = 0;
    for (var inv in ip.invoices) {
      final totals = InvoiceCalculationService.calculate(inv);
      totalRevenue    += totals.productsTotal;
      totalCommission += totals.commission;

      for (var prod in inv.products) {
        // Prefer matching by productId (stable); fall back to name for
        // older invoices saved before productId was tracked.
        final p = (prod.productId != null && prod.productId!.isNotEmpty)
            ? pp.getProductById(prod.productId!)
            : pp.getProductByName(prod.name);
        if (p != null) {
          totalCOGS += (p.lastPurchasePrice / 40) * prod.totalWeightKg;
        }
      }
    }

    // Commission is the shop's own earned income (this is a commission
    // shop), so it adds to profit rather than being netted against COGS.
    double grossProfit = totalRevenue - totalCOGS + totalCommission;
    double expenses = ip.invoices.fold(0.0, (s, i) => s + i.laborCharges + i.transportCharges + i.packingCharges + i.otherCharges);
    double netProfit = grossProfit - expenses;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profit Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profitCard('Total Revenue', totalRevenue, SColors.success),
          _profitCard('Total COGS', totalCOGS, SColors.catBlue),
          _profitCard('Gross Profit', grossProfit, Colors.teal),
          _profitCard('Total Expenses', expenses, SColors.warning),
          _profitCard('NET PROFIT', netProfit, netProfit >= 0 ? SColors.success : SColors.error, isMain: true),
          
          const SizedBox(height: 24),
          const Text('Product Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...pp.products.map((p) {
            double margin = p.pricePer40kg - p.lastPurchasePrice;
            double marginPct = p.pricePer40kg > 0 ? (margin / p.pricePer40kg) * 100 : 0;
            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text('Purchase: ${p.lastPurchasePrice} | Sale: ${p.pricePer40kg}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('PKR ${margin.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: margin >= 0 ? SColors.success : SColors.error)),
                    Text('${marginPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _profitCard(String title, double val, Color color, {bool isMain = false}) => Card(
    color: isMain ? color : null,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isMain ? Colors.white : Colors.grey)),
          Text('PKR ${val.toStringAsFixed(0)}', style: TextStyle(fontSize: isMain ? 20 : 16, fontWeight: FontWeight.bold, color: isMain ? Colors.white : color)),
        ],
      ),
    ),
  );
}

