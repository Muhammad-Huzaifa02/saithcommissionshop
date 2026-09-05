import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saithcommissionshop/data/models/shop_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

/// Streams the *active* shop's profile document.
///
/// Historically this read a single hardcoded `shop/info` document (one
/// shop, no tenancy). It now streams whichever shop id ShopContextProvider
/// says is active — call [setShopId] whenever that changes (main.dart wires
/// this automatically via ChangeNotifierProxyProvider). `shop`/`isSetup`/
/// `updateShopField` keep their old shape so existing screens
/// (admin_settings_page, customer_invoice_pages) don't need to change.
class ShopProvider extends ChangeNotifier {
  String? _shopId;
  Shop _shop = const Shop(id: '', name: '', ownerUid: '');
  bool _isLoaded = false;
  StreamSubscription? _sub;

  Shop get shop => _shop;
  bool get isLoaded => _isLoaded;
  bool get isSetup => _shop.name.isNotEmpty;

  /// Re-subscribes to the given shop's doc. Safe to call repeatedly with
  /// the same id (no-ops) or with null (clears state, e.g. on logout).
  void setShopId(String? shopId) {
    if (shopId == _shopId) return;
    _shopId = shopId;
    _sub?.cancel();
    _isLoaded = false;

    if (shopId == null) {
      _shop = const Shop(id: '', name: '', ownerUid: '');
      _isLoaded = true;
      notifyListeners();
      return;
    }

    _sub = FirebaseService.shopDocStream(shopId).listen((snap) {
      if (snap.exists) {
        _shop = Shop.fromMap(snap.id, snap.data() as Map<String, dynamic>);
      }
      _isLoaded = true;
      notifyListeners();
    }, onError: (_) {
      _isLoaded = true;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> updateShopField({
    String? name, String? phone, String? email,
    String? address, String? city, String? ntn, String? strn,
  }) async {
    if (_shopId == null) return;
    final update = <String, dynamic>{};
    if (name    != null) update['name']    = name;
    if (phone   != null) update['phone']   = phone;
    if (email   != null) update['email']   = email;
    if (address != null) update['address'] = address;
    if (city    != null) update['city']    = city;
    if (ntn     != null) update['ntn']     = ntn;
    if (strn    != null) update['strn']    = strn;
    await FirebaseService.updateShopDoc(_shopId!, update);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
