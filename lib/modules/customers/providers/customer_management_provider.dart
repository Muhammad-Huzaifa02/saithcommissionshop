import 'package:flutter/material.dart';
import 'package:saithcommissionshop/data/models/customer_extended.dart';

class CustomerManagementProvider extends ChangeNotifier {
  final List<CustomerExtended> _customers        = [];
  CustomerExtended?             _selectedCustomer;
  String                        _searchQuery      = '';
  String                        _filterTier       = 'all'; // all, Bronze, Silver, Gold, Platinum

  // ── Getters ──────────────────────────────────────────────────────────────
  List<CustomerExtended> get customers        => List.unmodifiable(_customers);
  CustomerExtended?      get selectedCustomer => _selectedCustomer;
  String                 get searchQuery      => _searchQuery;
  String                 get filterTier       => _filterTier;

  int get totalCustomers    => _customers.length;
  int get activeCustomers   => _customers.where((c) => c.isActive).length;
  int get goldCustomers     => _customers.where((c) => c.tier == 'Gold').length;
  int get platinumCustomers => _customers.where((c) => c.tier == 'Platinum').length;

  List<CustomerExtended> get filteredCustomers {
    var result = _customers.where((c) {
      final matchSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery);
      final matchTier = _filterTier == 'all' || c.tier == _filterTier;
      return matchSearch && matchTier;
    }).toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  void addCustomer(CustomerExtended customer) {
    _customers.add(customer);
    notifyListeners();
  }

  void updateCustomer(String id, CustomerExtended updated) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customers[index] = updated;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    if (_selectedCustomer?.id == id) _selectedCustomer = null;
    notifyListeners();
  }

  void selectCustomer(CustomerExtended? c) {
    _selectedCustomer = c;
    notifyListeners();
  }

  // ── Search & Filter ───────────────────────────────────────────────────────
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterTier(String tier) {
    _filterTier = tier;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterTier  = 'all';
    notifyListeners();
  }

  // ── Lookup ────────────────────────────────────────────────────────────────
  List<CustomerExtended> searchCustomers(String query) {
    final q = query.toLowerCase();
    return _customers
        .where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.phone.contains(query) ||
        c.email.toLowerCase().contains(q))
        .toList();
  }

  CustomerExtended? findById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
