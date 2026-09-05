import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saithcommissionshop/data/models/supplier_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class SupplierProvider extends ChangeNotifier {
  List<Supplier> _suppliers = [];
  bool _isLoaded = false;
  StreamSubscription? _sub;

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  bool get isLoaded => _isLoaded;

  SupplierProvider() { _subscribeToFirestore(); }

  void _subscribeToFirestore() {
    _sub = FirebaseService.suppliersStream().listen((snap) {
      _suppliers = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return Supplier(
          id: d.id,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          ntn: data['ntn'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      _isLoaded = true;
      notifyListeners();
    }, onError: (_) {
      _isLoaded = true;
      notifyListeners();
    });
  }

  Future<void> addSupplier(Supplier s) => FirebaseService.addSupplier(s.toMap());
  Future<void> updateSupplier(String id, Supplier s) => FirebaseService.updateSupplier(id, s.toMap());
  Future<void> deleteSupplier(String id) => FirebaseService.deleteSupplier(id);

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
