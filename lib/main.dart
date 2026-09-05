import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'package:saithcommissionshop/routes/app_routes.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/core/theme/theme_provider.dart';
import 'package:saithcommissionshop/data/services/connectivity_services.dart';
import 'package:saithcommissionshop/data/services/local_notification_service.dart';

import 'package:saithcommissionshop/modules/auth/providers/admin_user_provider.dart';
import 'package:saithcommissionshop/modules/home/providers/shop_context_provider.dart';
import 'package:saithcommissionshop/modules/home/providers/shop_provider.dart';
import 'package:saithcommissionshop/modules/home/providers/weather_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/ledger_provider.dart';
import 'package:saithcommissionshop/modules/customers/providers/customer_management_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/product_provider.dart';
import 'package:saithcommissionshop/modules/products/providers/stock_batch_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_provider.dart';
import 'package:saithcommissionshop/modules/orders/providers/invoice_history_provider.dart';
import 'package:saithcommissionshop/modules/cart/providers/cart_provider.dart';
import 'package:saithcommissionshop/modules/analytics/providers/advanced_analytics_provider.dart';
import 'package:saithcommissionshop/modules/suppliers/providers/supplier_provider.dart';
import 'package:saithcommissionshop/modules/purchase/providers/purchase_provider.dart';
import 'package:saithcommissionshop/modules/reminders/providers/reminder_provider.dart';
import 'package:saithcommissionshop/modules/reminders/providers/reminder_log_provider.dart';
import 'package:saithcommissionshop/modules/payment/providers/payment_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  try {
    await LocalNotificationService.init();
  } catch (e) {
    debugPrint('Error initializing local notifications: $e');
  }

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs          = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(MyApp(onboardingDone: onboardingDone));
}

class MyApp extends StatelessWidget {
  final bool onboardingDone;
  const MyApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),

        // Multi-tenant context
        ChangeNotifierProvider(create: (_) => ShopContextProvider()),

        // Firebase-backed real-time providers
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => LedgerProvider()),
        ChangeNotifierProxyProvider<ShopContextProvider, ShopProvider>(
          create: (_) => ShopProvider(),
          update: (_, shopContext, shopProvider) =>
              shopProvider!..setShopId(shopContext.currentShopId),
        ),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ReminderLogProvider()),
        ChangeNotifierProvider(create: (_) => StockBatchProvider()),

        // Lazy providers
        ChangeNotifierProvider(create: (_) => PaymentProvider(),            lazy: true),
        ChangeNotifierProvider(create: (_) => CartProvider(),               lazy: true),
        ChangeNotifierProvider(create: (_) => InvoiceHistoryProvider(),     lazy: true),
        ChangeNotifierProvider(create: (_) => AdvancedAnalyticsProvider(),  lazy: true),
        ChangeNotifierProvider(create: (_) => CustomerManagementProvider(), lazy: true),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Saith Commission Shop',
          theme:     AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/splash',
          routes:           AppRoutes.routes(onboardingDone),
          onGenerateRoute:  AppRoutes.generateRoute,
          onUnknownRoute:   (_) => MaterialPageRoute(
              builder: (_) => const NotFoundPage()),
          builder: (context, child) {
            final connectivity = context.watch<ConnectivityService>();
            return OfflineWrapper(
              isOnline: connectivity.isOnline,
              child:    child!,
            );
          },
        ),
      ),
    );
  }
}

// I'll keep OfflineWrapper and NotFoundPage here or move to core/widgets
class OfflineWrapper extends StatelessWidget {
  final bool   isOnline;
  final Widget child;
  const OfflineWrapper({super.key, required this.isOnline, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(child: child),
      if (!isOnline)
        Material(
          child: Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color:   Colors.red.shade700,
            child:   const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 14),
                SizedBox(width: 8),
                Text('No internet — showing cached data',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
    ],
  );
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Page not found',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(
                context, '/login'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}
