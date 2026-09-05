import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Central Firebase service — all Firestore collections and real-time streams
class FirebaseService {
  static final _db   = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

  // ── Storage ──────────────────────────────────────────────────────────────
  static Future<String> uploadProfileImage(String customerId, File file) async {
    final ref = _storage.ref().child('profiles').child('$customerId.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ── Collection references ─────────────────────────────────────────────────
  static CollectionReference get _products   => _db.collection('products');
  static CollectionReference get _invoices   => _db.collection('invoices');
  static CollectionReference get _customers  => _db.collection('customers');
  static CollectionReference get _ledger     => _db.collection('ledger');
  static CollectionReference get _admins     => _db.collection('admins');
  static CollectionReference get _suppliers  => _db.collection('suppliers');
  static CollectionReference get _purchases  => _db.collection('purchases');
  static DocumentReference  get _shopDoc     => _db.collection('shop').doc('info');

  // ── Auth ──────────────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStream => _auth.authStateChanges();

  static Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  static Future<UserCredential> createUser(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  static Future<void> signOut() => _auth.signOut();

  static Future<void> updatePassword(String newPassword) =>
      _auth.currentUser!.updatePassword(newPassword);

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  // ── Shop ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getShopInfo() async {
    final snap = await _shopDoc.get();
    return snap.exists ? snap.data() as Map<String, dynamic> : null;
  }

  static Future<void> saveShopInfo(Map<String, dynamic> data) =>
      _shopDoc.set(data, SetOptions(merge: true));

  static Stream<DocumentSnapshot> shopStream() => _shopDoc.snapshots();

  // ── Products ──────────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> productsStream() =>
      _products.orderBy('name').snapshots();

  static Future<void> addProduct(Map<String, dynamic> data) =>
      _products.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> updateProduct(String id, Map<String, dynamic> data) =>
      _products.doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});

  static Future<void> deleteProduct(String id) => _products.doc(id).delete();

  /// Atomically adjusts stock by [changeKg] (positive to add, negative to
  /// deduct). Uses FieldValue.increment so concurrent calls (e.g. two
  /// purchases or a purchase + a manual adjustment happening close together)
  /// can never silently overwrite each other the way writing a precomputed
  /// absolute value can.
  static Future<void> adjustStock(String id, double changeKg) =>
      _products.doc(id).update({
        'availableStockKg': FieldValue.increment(changeKg),
        'updatedAt':        FieldValue.serverTimestamp(),
      });

  // ── Customers ─────────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> customersStream() =>
      _customers.orderBy('createdAt', descending: true).snapshots();

  static Future<DocumentReference> addCustomer(Map<String, dynamic> data) =>
      _customers.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> addCustomerWithId(String id, Map<String, dynamic> data) =>
      _customers.doc(id).set({...data, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> updateCustomer(String id, Map<String, dynamic> data) =>
      _customers.doc(id).update(data);

  static Future<QuerySnapshot> getCustomerByPhone(String phone) =>
      _customers.where('phone', isEqualTo: phone).limit(1).get();

  static Future<QuerySnapshot> getCustomerByEmail(String email) =>
      _customers.where('email', isEqualTo: email).limit(1).get();

  // ── Invoices ──────────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> invoicesStream() =>
      _invoices.snapshots();

  static Stream<QuerySnapshot> customerInvoicesStream(String customerId) =>
      _invoices.where('customerId', isEqualTo: customerId).snapshots();

  static Stream<QuerySnapshot> pendingInvoicesStream() =>
      _invoices.where('isPaid', isEqualTo: false).snapshots();

  static Future<DocumentReference> addInvoice(Map<String, dynamic> data) =>
      _invoices.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> updateInvoice(String id, Map<String, dynamic> data) =>
      _invoices.doc(id).update({...data, 'updatedAt': FieldValue.serverTimestamp()});

  static Future<void> markInvoicePaid(String id, double amountPaid) =>
      _invoices.doc(id).update({
        'isPaid':     true,
        'amountPaid': amountPaid,
        'paidAt':     FieldValue.serverTimestamp(),
      });

  static Future<void> deleteInvoice(String id) => _invoices.doc(id).delete();

  // ── Ledger ────────────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> customerLedgerStream(String customerId) =>
      _ledger.where('customerId', isEqualTo: customerId).snapshots();

  static Future<void> addLedgerEntry(Map<String, dynamic> data) =>
      _ledger.add({...data, 'dateTime': FieldValue.serverTimestamp()});

  // ── Admins ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getAdminProfile(String uid) async {
    final snap = await _admins.doc(uid).get();
    return snap.exists ? snap.data() as Map<String, dynamic> : null;
  }

  static Future<void> saveAdminProfile(String uid, Map<String, dynamic> data) =>
      _admins.doc(uid).set(data, SetOptions(merge: true));

  static Future<bool> hasAnyAdmin() async {
    final snap = await _admins.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  static Stream<QuerySnapshot> allAdminsStream() => _admins.snapshots();

  // ── Suppliers ─────────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> suppliersStream() =>
      _suppliers.orderBy('name').snapshots();

  static Future<DocumentReference> addSupplier(Map<String, dynamic> data) =>
      _suppliers.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  static Future<void> updateSupplier(String id, Map<String, dynamic> data) =>
      _suppliers.doc(id).update(data);

  static Future<void> deleteSupplier(String id) => _suppliers.doc(id).delete();

  // ── Purchases ─────────────────────────────────────────────────────────────
  static Stream<QuerySnapshot> purchasesStream() =>
      _purchases.orderBy('date', descending: true).snapshots();

  /// Atomically applies a net stock change per product (used when editing
  /// an invoice: positive delta restores stock, negative deducts it).
  /// Rejects the whole edit if any product can't be resolved or would go
  /// negative — never guesses by falling back to an arbitrary product.
  static Future<void> applyStockDeltas({
    required Map<String, double> deltaByProductId,
    required String reference,
    required String adminId,
    String? notes,
  }) async {
    if (deltaByProductId.isEmpty) return;
    if (_auth.currentUser == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'The caller is not authenticated.',
      );
    }

    await _db.runTransaction((transaction) async {
      final ids = deltaByProductId.keys.toList();
      final refs = ids.map((id) => _products.doc(id)).toList();
      final snapshots = await Future.wait(refs.map((r) => transaction.get(r)));

      final newValues = <String, double>{};
      for (var i = 0; i < ids.length; i++) {
        final snap = snapshots[i];
        if (!snap.exists) {
          throw Exception('Product ${ids[i]} no longer exists — edit cancelled.');
        }
        final data = snap.data() as Map<String, dynamic>;
        final current = (data['availableStockKg'] as num?)?.toDouble() ?? 0.0;
        final newVal = current + deltaByProductId[ids[i]]!;
        if (newVal < 0) {
          throw Exception(
            'Not enough stock to apply this change (product ${ids[i]}: '
            'have ${current.toStringAsFixed(1)} kg, need ${(-deltaByProductId[ids[i]]!).toStringAsFixed(1)} kg) — edit cancelled.',
          );
        }
        newValues[ids[i]] = newVal;
      }

      for (final id in ids) {
        transaction.update(_products.doc(id), {
          'availableStockKg': newValues[id],
          'updatedAt':        FieldValue.serverTimestamp(),
        });
        final historyRef = _db.collection('stock_history').doc();
        transaction.set(historyRef, {
          'productId': id,
          'changeKg':  deltaByProductId[id],
          'reference': reference,
          'adminId':   adminId,
          'notes':     notes,
          'date':      FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<DocumentReference> addPurchase(Map<String, dynamic> data) =>
      _purchases.add({...data, 'createdAt': FieldValue.serverTimestamp()});

  /// Saves a purchase order and applies all of its stock effects atomically:
  /// the purchase record, every item's stock increment, its lastPurchasePrice
  /// update, and its stock_history entry either all succeed or all fail
  /// together. This replaces doing these as separate sequential awaits in a
  /// loop, where a crash/error partway through could leave the purchase
  /// logged but only some items' stock actually updated.
  static Future<void> savePurchaseTransaction({
    required Map<String, dynamic> purchaseData,
    required List<Map<String, dynamic>> stockAdditions,
  }) async {
    final batch = _db.batch();

    final purchaseRef = _purchases.doc();
    batch.set(purchaseRef, {...purchaseData, 'createdAt': FieldValue.serverTimestamp()});

    for (final item in stockAdditions) {
      final productRef = _products.doc(item['productId'] as String);
      final update = <String, dynamic>{
        'availableStockKg': FieldValue.increment(item['changeKg'] as double),
        'updatedAt':        FieldValue.serverTimestamp(),
      };
      if (item['lastPurchasePrice'] != null) {
        update['lastPurchasePrice'] = item['lastPurchasePrice'];
      }
      batch.update(productRef, update);

      final historyRef = _stockHistory.doc();
      batch.set(historyRef, {
        'productId': item['productId'],
        'changeKg':  item['changeKg'],
        'reference': item['reference'],
        'adminId':   item['adminId'],
        'notes':     item['notes'],
        'date':      FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ── Stock History ────────────────────────────────────────────────────────
  static CollectionReference get _stockHistory => _db.collection('stock_history');

  static Future<void> addStockHistory(Map<String, dynamic> data) =>
      _stockHistory.add({
        ...data,
        'date': FieldValue.serverTimestamp(),
      });

  static Stream<QuerySnapshot> stockHistoryStream(String productId) =>
      _stockHistory
          .where('productId', isEqualTo: productId)
          .orderBy('date', descending: true)
          .snapshots();

  // ── Stats / Analytics (aggregated) ────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait([
      _invoices.get(),
      _customers.get(),
      _products.get(),
      _invoices.where('isPaid', isEqualTo: false).get(),
    ]);

    final allInvoices  = results[0];
    final allCustomers = results[1];
    final allProducts  = results[2];
    final pending      = results[3];

    double totalSales   = 0;
    double totalPending = 0;

    for (final doc in allInvoices.docs) {
      final d = doc.data() as Map<String, dynamic>;
      totalSales += (d['grandTotal'] as num?)?.toDouble() ?? 0;
    }
    for (final doc in pending.docs) {
      final d = doc.data() as Map<String, dynamic>;
      totalPending += ((d['grandTotal'] as num?)?.toDouble() ?? 0) -
          ((d['amountPaid'] as num?)?.toDouble() ?? 0);
    }

    return {
      'totalInvoices':  allInvoices.size,
      'totalCustomers': allCustomers.size,
      'totalProducts':  allProducts.size,
      'pendingCount':   pending.size,
      'totalSales':     totalSales,
      'totalPending':   totalPending,
    };
  }

  // ── Transactional operations ────────────────────────────────────────────
  /// Saves an invoice and deducts stock atomically. Each entry in
  /// [stockDeductions] must have: 'productId' (String), 'changeKg' (double,
  /// negative for a sale), and may include 'reference', 'adminId', 'notes'
  /// for the stock_history record.
  ///
  /// Runs as a real Firestore transaction (not a batch): stock is read
  /// fresh at commit time, so two concurrent checkouts can no longer
  /// overwrite each other's deduction. If the current stock isn't enough
  /// to cover a deduction, the whole transaction throws and NOTHING is
  /// written — no invoice, no ledger entry, no stock change — instead of
  /// silently completing a sale that oversells inventory.
  static Future<void> saveInvoiceTransaction({
    required String invoiceId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> stockDeductions,
    required Map<String, dynamic> ledgerData,
  }) async {
    // 0. Auth check
    if (_auth.currentUser == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'The caller is not authenticated.',
      );
    }

    await _db.runTransaction((transaction) async {
      // 1. All reads must happen before any writes in a Firestore transaction.
      final productRefs = stockDeductions
          .map((d) => _products.doc(d['productId'] as String))
          .toList();
      final snapshots = await Future.wait(
        productRefs.map((ref) => transaction.get(ref)),
      );

      // 2. Validate stock against the value read *inside this transaction*
      //    (not a locally-cached copy) and compute new values.
      final newStockValues = <double>[];
      for (var i = 0; i < stockDeductions.length; i++) {
        final snap = snapshots[i];
        final changeKg = (stockDeductions[i]['changeKg'] as num).toDouble();

        if (!snap.exists) {
          throw Exception(
            'Product "${stockDeductions[i]['name'] ?? stockDeductions[i]['productId']}" '
            'no longer exists — sale cancelled.',
          );
        }

        final data = snap.data() as Map<String, dynamic>;
        final currentStock = (data['availableStockKg'] as num?)?.toDouble() ?? 0.0;
        final newStock = currentStock + changeKg;

        if (newStock < 0) {
          throw Exception(
            'Not enough stock for "${stockDeductions[i]['name'] ?? stockDeductions[i]['productId']}" '
            '(have ${currentStock.toStringAsFixed(1)} kg, need ${(-changeKg).toStringAsFixed(1)} kg) — sale cancelled.',
          );
        }
        newStockValues.add(newStock);
      }

      // 3. All validation passed — now perform every write.
      final invRef = _invoices.doc(invoiceId);
      transaction.set(invRef, {
        ...invoiceData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var i = 0; i < stockDeductions.length; i++) {
        transaction.update(productRefs[i], {
          'availableStockKg': newStockValues[i],
          'updatedAt':        FieldValue.serverTimestamp(),
        });

        final historyRef = _db.collection('stock_history').doc();
        transaction.set(historyRef, {
          'productId':  stockDeductions[i]['productId'],
          'changeKg':   stockDeductions[i]['changeKg'],
          'reference':  stockDeductions[i]['reference'],
          'adminId':    stockDeductions[i]['adminId'],
          'notes':      stockDeductions[i]['notes'],
          'date':       FieldValue.serverTimestamp(),
        });
      }

      final ledgerRef = _ledger.doc();
      transaction.set(ledgerRef, {
        ...ledgerData,
        'dateTime': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Multi-tenant: Shops / Members / Roles ───────────────────────────────
  // These are additive — the old singleton `shop/info` doc/methods above
  // are left in place until the retrofit phase re-points every shop-scoped
  // collection at `shopId` and the migration script has run. Do not read
  // from both the singleton and the new `shops` collection in the same
  // screen once the retrofit lands, or you'll show stale data.
  static CollectionReference get _shops        => _db.collection('shops');
  static CollectionReference get _shopMembers  => _db.collection('shop_members');
  static CollectionReference _rolesFor(String shopId) =>
      _shops.doc(shopId).collection('roles');

  static Future<DocumentSnapshot> getShop(String shopId) => _shops.doc(shopId).get();

  static Stream<DocumentSnapshot> shopDocStream(String shopId) =>
      _shops.doc(shopId).snapshots();

  static Future<void> updateShopDoc(String shopId, Map<String, dynamic> data) =>
      _shops.doc(shopId).update(data);

  /// All active/inactive ShopMember docs for one Firebase Auth uid, across
  /// every shop they belong to. Used by ShopContextProvider to build the
  /// Shop Switcher and to resolve which shop to open on login.
  static Future<QuerySnapshot> shopMembersForUser(String uid) =>
      _shopMembers.where('uid', isEqualTo: uid).get();

  static Future<QuerySnapshot> shopMembersForShop(String shopId) =>
      _shopMembers.where('shopId', isEqualTo: shopId).get();

  static Future<DocumentSnapshot?> getRole(String shopId, String roleId) async {
    final snap = await _rolesFor(shopId).doc(roleId).get();
    return snap.exists ? snap : null;
  }

  static Stream<QuerySnapshot> rolesStream(String shopId) =>
      _rolesFor(shopId).snapshots();

  static Future<void> saveRole(String shopId, String roleId, Map<String, dynamic> data) =>
      _rolesFor(shopId).doc(roleId).set(data, SetOptions(merge: true));

  /// Creates a brand-new shop end to end: the shop doc, its five seeded
  /// default roles, and an Owner ShopMember doc for [ownerUid]. Runs as a
  /// batch so a failure partway through can't leave a half-created shop
  /// (a shop doc with no roles, or an owner with no membership record).
  ///
  /// Returns the new shop's id.
  static Future<String> createShopWithOwner({
    required String ownerUid,
    required Map<String, dynamic> shopData,
    required String ownerName,
    required String ownerPhone,
    required String ownerEmail,
    required List<Map<String, dynamic>> defaultRoles,
  }) async {
    final shopRef = _shops.doc();
    final batch = _db.batch();

    batch.set(shopRef, {
      ...shopData,
      'ownerUid': ownerUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (final role in defaultRoles) {
      final roleId = role['id'] as String;
      final roleData = Map<String, dynamic>.from(role)..remove('id');
      batch.set(_rolesFor(shopRef.id).doc(roleId), {
        ...roleData,
        'shopId': shopRef.id,
      });
    }

    final memberRef = _shopMembers.doc();
    batch.set(memberRef, {
      'shopId': shopRef.id,
      'uid': ownerUid,
      'roleId': 'owner',
      'name': ownerName,
      'phone': ownerPhone,
      'email': ownerEmail,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return shopRef.id;
  }

  /// Adds a new employee to an existing shop: creates their ShopMember doc
  /// and writes an audit_logs entry. Does NOT create the Firebase Auth
  /// account itself — that must happen first (e.g. via a callable Cloud
  /// Function using the Admin SDK, so the owner's own session isn't
  /// disturbed by client-side createUserWithEmailAndPassword) and the
  /// resulting uid passed in here.
  static Future<String> addShopMember({
    required String shopId,
    required String uid,
    required String roleId,
    required Map<String, dynamic> memberData,
    required String actorUid,
    required String actorName,
  }) async {
    final memberRef = _shopMembers.doc();
    final batch = _db.batch();

    batch.set(memberRef, {
      ...memberData,
      'shopId': shopId,
      'uid': uid,
      'roleId': roleId,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_auditLogs.doc(), {
      'shopId': shopId,
      'actorUid': actorUid,
      'actorName': actorName,
      'action': 'employee_added',
      'entityType': 'shop_member',
      'entityId': memberRef.id,
      'summary': '$actorName added ${memberData['name'] ?? 'a new employee'}',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return memberRef.id;
  }

  // ── Audit logs ───────────────────────────────────────────────────────────
  static CollectionReference get _auditLogs => _db.collection('audit_logs');

  static Future<void> addAuditLog({
    required String shopId,
    required String actorUid,
    required String actorName,
    required String action,
    required String entityType,
    required String entityId,
    required String summary,
  }) =>
      _auditLogs.add({
        'shopId': shopId,
        'actorUid': actorUid,
        'actorName': actorName,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'summary': summary,
        'createdAt': FieldValue.serverTimestamp(),
      });

  static Stream<QuerySnapshot> auditLogsStream(String shopId) => _auditLogs
      .where('shopId', isEqualTo: shopId)
      .orderBy('createdAt', descending: true)
      .snapshots();

  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _db.batch();
    for (final op in operations) {
      final ref  = op['ref']  as DocumentReference;
      final data = op['data'] as Map<String, dynamic>;
      final type = op['type'] as String;
      if      (type == 'set')    batch.set(ref, data);
      else if (type == 'update') batch.update(ref, data);
      else if (type == 'delete') batch.delete(ref);
    }
    await batch.commit();
  }
}
