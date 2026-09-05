import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/auth/views/splash_page.dart';
import 'package:saithcommissionshop/modules/auth/views/onboarding_page.dart';
import 'package:saithcommissionshop/modules/auth/views/unified_login_page.dart';
import 'package:saithcommissionshop/modules/home/views/admin_home_page.dart';
import 'package:saithcommissionshop/modules/analytics/views/admin_analytics_page.dart';
import 'package:saithcommissionshop/modules/products/views/admin_products_page.dart';
import 'package:saithcommissionshop/modules/products/views/admin_product_stock_page.dart';
import 'package:saithcommissionshop/modules/orders/views/admin_manual_invoice_page.dart';
import 'package:saithcommissionshop/modules/profile/views/admin_profile_page.dart';
import 'package:saithcommissionshop/modules/settings/views/admin_settings_page.dart';
import 'package:saithcommissionshop/modules/customers/views/admin_customers_page.dart';
import 'package:saithcommissionshop/modules/settings/views/price_board_page.dart';
import 'package:saithcommissionshop/modules/reminders/views/reminder_logs_page.dart';
import 'package:saithcommissionshop/modules/analytics/views/export_page.dart';
import 'package:saithcommissionshop/modules/suppliers/views/admin_suppliers_page.dart';
import 'package:saithcommissionshop/modules/purchase/views/admin_purchase_page.dart';
import 'package:saithcommissionshop/modules/analytics/views/admin_profit_page.dart';
import 'package:saithcommissionshop/modules/reminders/views/reminder_history_page.dart';
import 'package:saithcommissionshop/modules/auth/views/customer_signup_page.dart';
import 'package:saithcommissionshop/modules/home/views/customer_home_page.dart';
import 'package:saithcommissionshop/modules/profile/views/customer_profile_page.dart';
import 'package:saithcommissionshop/modules/customers/views/customer_ledger_page.dart';
import 'package:saithcommissionshop/modules/cart/views/cart_page.dart';
import 'package:saithcommissionshop/modules/cart/views/checkout_page.dart';
import 'package:saithcommissionshop/modules/orders/views/order_history_page.dart';
import 'package:saithcommissionshop/modules/notifications/views/notifications_page.dart';
import 'package:saithcommissionshop/modules/orders/views/invoice_list_page.dart';
import 'package:saithcommissionshop/modules/scanner/views/invoice_scanner_page.dart';
import 'package:saithcommissionshop/modules/scanner/views/invoice_lookup_page.dart';
import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/core/utils/overflow_handler.dart';
import 'package:saithcommissionshop/data/services/local_notification_service.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes(bool onboardingDone) => {
    '/splash':           (context) => SplashScreenRouter(onboardingDone: onboardingDone),
    '/onboarding':       (context) => const OnboardingPage(),
    '/login':            (context) => const UnifiedLoginPage(),
    '/admin-home':       (context) => const AuthGuard(child: AdminHomePage()),
    '/admin-analytics':  (context) => const AuthGuard(child: AdminAnalyticsPage()),
    '/admin-products':   (context) => const AuthGuard(child: AdminProductsPage()),
    '/admin-stock':      (context) => const AuthGuard(child: AdminProductStockPage()),
    '/admin-invoice':    (context) => const AuthGuard(child: AdminManualInvoicePage()),
    '/admin-profile':    (context) => const AuthGuard(child: AdminProfilePage()),
    '/admin-settings':   (context) => const AuthGuard(child: AdminSettingsPage()),
    '/admin-customers':  (context) => const AuthGuard(child: AdminCustomersPage()),
    '/export':           (context) => const AuthGuard(child: ExportPage()),
    '/invoices':         (context) => const AuthGuard(child: InvoiceListPage()),
    '/price-board':      (context) => const PriceBoardPage(),
    '/reminder-logs':    (context) => const AuthGuard(child: ReminderLogsPage()),
    '/admin-suppliers':  (context) => const AuthGuard(child: AdminSuppliersPage()),
    '/admin-purchases':  (context) => const AuthGuard(child: AdminPurchasePage()),
    '/admin-profit':     (context) => const AuthGuard(child: AdminProfitDashboardPage()),
    '/reminder-history': (context) => const AuthGuard(child: ReminderHistoryPage()),
    '/customer-signup':  (context) => const CustomerSignupPage(),
    '/customer-home':    (context) => const CustomerAuthGuard(child: CustomerHomePage()),
    '/customer-profile': (context) => const CustomerAuthGuard(child: CustomerProfilePage()),
    '/cart':             (context) => const CustomerAuthGuard(child: CartPage()),
    '/checkout':         (context) => const CustomerAuthGuard(child: CheckoutPage()),
    '/order-history':    (context) => const CustomerAuthGuard(child: OrderHistoryPage()),
    '/notifications':    (context) => const NotificationsPage(),
    '/scan-product':     (context) => const InvoiceScannerPage(),
    '/scan-invoice':     (context) => const InvoiceLookupPage(),
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    if (settings.name == '/customer-ledger') {
      final raw = settings.arguments;
      if (raw == null) {
        return MaterialPageRoute(
            builder: (_) => const CustomerLedgerPage(
                customerId: '', customerName: 'Customer'));
      }
      final args = Map<String, dynamic>.from(raw as Map);
      return MaterialPageRoute(
        builder: (_) => CustomerLedgerPage(
          customerId:   (args['customerId']   ?? '').toString(),
          customerName: (args['customerName'] ?? '').toString(),
        ),
      );
    }
    return null;
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ok = context.watch<AdminUserProvider>().isLoggedIn;
    if (!ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          Navigator.pushReplacementNamed(context, '/login'));
      return const AppPageScaffold(
          body: CustomLoader(size: 40));
    }
    return child;
  }
}

class CustomerAuthGuard extends StatelessWidget {
  final Widget child;
  const CustomerAuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ok = context.watch<CustomerProvider>().isLoggedIn;
    if (!ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          Navigator.pushReplacementNamed(context, '/login'));
      return const AppPageScaffold(
          body: CustomLoader(size: 40));
    }
    return child;
  }
}

class SplashScreenRouter extends StatefulWidget {
  final bool onboardingDone;
  const SplashScreenRouter({super.key, required this.onboardingDone});

  @override
  State<SplashScreenRouter> createState() => _SplashScreenRouterState();
}

class _SplashScreenRouterState extends State<SplashScreenRouter> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try { await LocalNotificationService.init(); } catch (_) {}
    });
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          widget.onboardingDone ? '/login' : '/onboarding',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
