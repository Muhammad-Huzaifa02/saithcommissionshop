import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saithcommissionshop/data/models/shop_member_model.dart';
import 'package:saithcommissionshop/data/models/role_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

/// The single source of truth for "which shop is active, who is the caller
/// in that shop, and what are they allowed to do".
///
/// Every shop-scoped read/write elsewhere in the app should go through
/// `currentShopId` — never hardcode a shop id, and never trust a shopId
/// that came from outside this provider (that's what the Firestore
/// Security Rules independently re-check server-side).
class ShopContextProvider extends ChangeNotifier {
  static const _lastShopPrefsKey = 'last_active_shop_id';

  String? _currentShopId;
  List<ShopMember> _memberships = []; // every shop this uid belongs to
  ShopMember? _currentMember;
  Role? _currentRole;
  bool _isLoading = true;

  String? get currentShopId => _currentShopId;
  ShopMember? get currentMember => _currentMember;
  Role? get currentRole => _currentRole;
  List<ShopMember> get memberships => List.unmodifiable(_memberships);
  bool get isLoading => _isLoading;
  bool get hasShop => _currentShopId != null && _currentMember != null;
  bool get hasMultipleShops => _memberships.length > 1;

  List<String> get permissions => _currentRole?.permissions ?? const [];
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Call once after Firebase Auth resolves a signed-in user (e.g. from a
  /// splash/auth-gate widget). Loads every shop this uid belongs to and
  /// activates the previously-used shop if the user still belongs to it,
  /// otherwise the first active membership found.
  Future<void> loadForUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    final snap = await FirebaseService.shopMembersForUser(uid);
    _memberships = snap.docs
        .map((d) => ShopMember.fromMap(d.id, d.data() as Map<String, dynamic>))
        .where((m) => m.isActive)
        .toList();

    if (_memberships.isEmpty) {
      _currentShopId = null;
      _currentMember = null;
      _currentRole = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastShopPrefsKey);
    final match = _memberships.where((m) => m.shopId == lastId);
    final chosen = match.isNotEmpty ? match.first : _memberships.first;

    await switchShop(chosen.shopId);
  }

  /// Switches the active shop context. Every stream/provider built on top
  /// of `currentShopId` should be listening to this provider so switching
  /// re-points the whole app's data without a manual reload.
  Future<void> switchShop(String shopId) async {
    _isLoading = true;
    notifyListeners();

    final member = _memberships.where((m) => m.shopId == shopId);
    if (member.isEmpty) {
      // Not a shop this uid belongs to — refuse locally. The server-side
      // Security Rules are the real enforcement; this just avoids a
      // pointless round trip.
      _isLoading = false;
      notifyListeners();
      return;
    }

    _currentMember = member.first;
    _currentShopId = shopId;

    final roleSnap = await FirebaseService.getRole(shopId, _currentMember!.roleId);
    _currentRole = roleSnap != null
        ? Role.fromMap(roleSnap.id, roleSnap.data() as Map<String, dynamic>)
        : null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShopPrefsKey, shopId);

    _isLoading = false;
    notifyListeners();
  }

  /// Called right after a brand-new shop + owner ShopMember + default
  /// roles have been created (see FirebaseService.createShopWithOwner),
  /// so the new shop becomes active immediately without re-querying.
  void adoptNewShop(ShopMember ownerMembership, Role ownerRole) {
    _memberships = [..._memberships, ownerMembership];
    _currentMember = ownerMembership;
    _currentShopId = ownerMembership.shopId;
    _currentRole = ownerRole;
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _currentShopId = null;
    _memberships = [];
    _currentMember = null;
    _currentRole = null;
    _isLoading = false;
    notifyListeners();
  }
}
