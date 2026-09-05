import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:saithcommissionshop/data/models/customer_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers      = [];
  Customer?      _currentCustomer;
  bool           _isLoaded       = false;
  StreamSubscription? _sub;

  List<Customer> get customers       => List.unmodifiable(_customers);
  Customer?      get currentCustomer => _currentCustomer;
  bool           get isLoggedIn      => _currentCustomer != null;
  int            get totalCustomers  => _customers.length;
  bool           get isLoaded        => _isLoaded;

  String get nextCustomerId {
    if (_customers.isEmpty) return 'CUST-0001';
    
    int maxNum = 0;
    for (final c in _customers) {
      final id = c.customerId;
      if (id.startsWith('CUST-')) {
        final numPart = int.tryParse(id.replaceFirst('CUST-', ''));
        if (numPart != null && numPart > maxNum) {
          maxNum = numPart;
        }
      }
    }
    
    return 'CUST-${(maxNum + 1).toString().padLeft(4, '0')}';
  }

  CustomerProvider() { _subscribeToFirestore(); }

  void _subscribeToFirestore() {
    _sub = FirebaseService.customersStream().listen((snap) {
      _customers = snap.docs.map((d) => _fromFirestore(d)).toList();
      _isLoaded  = true;
      // Update currentCustomer if logged in
      if (_currentCustomer != null) {
        try {
          _currentCustomer = _customers.firstWhere(
                  (c) => c.id == _currentCustomer!.id);
        } catch (_) {}
      }
      notifyListeners();
    }, onError: (_) {
      _isLoaded = true;
      notifyListeners();
    });
  }

  // ── Model conversion ──────────────────────────────────────────────────────
  static Customer _fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Customer(
      id:         doc.id,
      customerId: d['customerId'] as String? ?? 'CUST-0000',
      name:       d['name']       as String? ?? '',
      phone:      d['phone']      as String? ?? '',
      email:      d['email']      as String? ?? '',
      address:    d['address']    as String? ?? '',
      password:   d['password']   as String? ?? '',
      imageUrl:   d['imageUrl']   as String?,
      createdAt:  d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive:   d['isActive']   as bool?   ?? true,
    );
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<String?> register({
    required String name,
    required String phone,
    String  email    = '',
    required String password,
    String  address  = '',
  }) async {
    try {
      final phoneTrim = phone.trim();
      final emailTrim = email.trim();

      // 1. Try to create the user directly in Firebase Auth
      String uid;
      try {
        if (emailTrim.isEmpty) return 'Email is required for registration.';
        
        // Ensure no leftover anonymous session is causing conflicts
        if (auth.FirebaseAuth.instance.currentUser != null) {
          await auth.FirebaseAuth.instance.signOut();
        }

        final authResult = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailTrim,
          password: password,
        );
        uid = authResult.user!.uid;
      } on auth.FirebaseAuthException catch (e) {
        debugPrint('Auth Error Code: ${e.code}');
        if (e.code == 'email-already-in-use') return 'This email is already registered.';
        if (e.code == 'weak-password') return 'Password is too weak.';
        if (e.code == 'admin-restricted-operation') {
          return 'SECURITY ERROR: Go to Firebase Console > Auth > Settings > User Actions and UNCHECK "Email enumeration protection".';
        }
        return e.message ?? 'Authentication error';
      }

      // 2. Profile creation in Firestore
      final hashed = sha256.convert(utf8.encode(password.trim())).toString();
      final formattedId = nextCustomerId;
      await FirebaseService.addCustomerWithId(uid, {
        'customerId': formattedId,
        'name':       name.trim(),
        'phone':      phoneTrim,
        'email':      emailTrim,
        'address':    address.trim(),
        'password':   hashed,
        'isActive':   true,
      });

      _currentCustomer = Customer(
        id:         uid,
        customerId: formattedId,
        name:       name.trim(),
        phone:      phoneTrim,
        email:      emailTrim,
        address:    address.trim(),
        password:   hashed,
        createdAt:  DateTime.now(),
      );
      notifyListeners();
      return null;
    } catch (e) {
      return 'Registration failed: ${e.toString()}';
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  // Firebase Auth is the ONLY thing that decides whether a login succeeds.
  // (Previously, a client-side password-hash comparison against Firestore
  // could mark the user "logged in" even when the Firebase Auth sign-in
  // attempt failed and was silently swallowed — that let people browse and
  // add to cart with no real session, then hit "session expired" only at
  // checkout, when Firestore rules finally required request.auth != null.)
  Future<bool> login({required String identifier, required String password}) async {
    try {
      final idTrim = identifier.trim();
      final passTrim = password.trim();

      // 1. Make sure the customer list is loaded so a phone/customer-ID
      //    identifier can be resolved to the email Firebase Auth needs.
      if (!_isLoaded || _customers.isEmpty) {
        debugPrint('Waiting for customers to load... (count: ${_customers.length})');
        for (int i = 0; i < 10; i++) {
          if (_isLoaded && _customers.isNotEmpty) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // 2. Resolve the identifier to an email — this lookup is ONLY to find
      //    which email to authenticate with. It does not authorize anything.
      Customer? matched;
      try {
        matched = _customers.firstWhere(
          (c) => c.phone == idTrim || c.email == idTrim || c.id == idTrim,
        );
      } catch (_) {
        matched = null;
      }

      final emailToUse = idTrim.contains('@') ? idTrim : matched?.email;
      if (emailToUse == null || emailToUse.isEmpty) {
        debugPrint('Login failed: no account found for "$idTrim"');
        return false;
      }

      // 3. The ONE real authentication check. If this throws, login fails —
      //    no more silent fallback that leaves the app in a half-logged-in
      //    state.
      final credential = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse,
        password: passTrim,
      );
      final uid = credential.user!.uid;

      // 4. Load the matching profile. Prefer matching by uid (authoritative);
      //    fall back to the identifier match in case the Firestore stream
      //    hasn't caught up yet.
      Customer? customer;
      try {
        customer = _customers.firstWhere((c) => c.id == uid);
      } catch (_) {
        customer = matched;
      }

      if (customer == null) {
        debugPrint('Login failed: authenticated but no matching customer profile for uid $uid');
        return false;
      }

      _currentCustomer = customer;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth login failed: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Login state error: $e');
      return false;
    }
  }

  void logout() {
    _currentCustomer = null;
    notifyListeners();
  }

  // ── Lookup ────────────────────────────────────────────────────────────────
  Customer? getCustomerById(String id) {
    try { return _customers.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  List<Customer> searchCustomers(String query) {
    final q = query.toLowerCase();
    return _customers.where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.phone.contains(query)).toList();
  }

  // ── Update ────────────────────────────────────────────────────────────────
  Future<void> updateCustomer(String id, Customer updated) async {
    await FirebaseService.updateCustomer(id, {
      'name':     updated.name,
      'phone':    updated.phone,
      'email':    updated.email,
      'address':  updated.address,
      'imageUrl': updated.imageUrl,
    });
    if (_currentCustomer?.id == id) {
      _currentCustomer = updated;
      notifyListeners();
    }
  }

  Future<void> uploadProfilePicture(String id, File file) async {
    final url = await FirebaseService.uploadProfileImage(id, file);
    await FirebaseService.updateCustomer(id, {'imageUrl': url});
    if (_currentCustomer?.id == id) {
      _currentCustomer = _currentCustomer!.copyWith(imageUrl: url);
      notifyListeners();
    }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
