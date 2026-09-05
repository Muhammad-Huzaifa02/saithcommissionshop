// Batch 1 migration script — stamps the existing single-tenant Saith
// Commission Shop data as the platform's first shop.
//
// DO NOT RUN AGAINST PRODUCTION until:
//   1. Batches 1-6 (foundation through settings) are built and proven
//      against fresh test shops.
//   2. A full Firestore export/backup of production has been taken.
//   3. This script has been run once against a copy/staging project and
//      every existing screen manually verified against the result.
//
// Usage (from the project's tool/ directory, with Firebase CLI creds or a
// service account configured for the target project):
//   dart run tool/migrate_to_multi_tenant.dart --project=<staging-project-id>
//
// This performs step-by-step what Section C of the upgrade plan describes:
//   1. Read the old singleton `shop/info` doc.
//   2. Create a new `shops/{shopId}` doc from it (ownerUid = the first
//      admin found in `admins` with role superAdmin, or --owner-uid flag).
//   3. Seed the 5 default `roles` under that shop.
//   4. Create a `shop_members` doc for every existing `admins` doc, mapping
//      the old AdminRole enum to the new roleId.
//   5. Stamp shopId onto every doc in products/customers/suppliers/
//      invoices/purchases/stock_history.
//   6. Rebuild `ledger` into customer_ledger_entries / supplier_ledger_entries
//      with a running balance computed in date order.
//
// Nothing is deleted — old fields/collections are left in place so the
// migration is reversible until manually cleaned up after verification.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

const _oldAdminRoleToNewRoleId = {
  'superAdmin': 'owner',
  'manager': 'manager',
  'staff': 'sales_staff',
};

Future<void> main(List<String> args) async {
  final ownerUidArg = _argValue(args, 'owner-uid');

  await Firebase.initializeApp();
  final db = FirebaseFirestore.instance;

  stdout.writeln('== Mandi Platform migration: single-tenant -> multi-tenant ==');

  // 1. Read the old singleton shop doc.
  final oldShopSnap = await db.collection('shop').doc('info').get();
  final oldShopData = oldShopSnap.data() ?? <String, dynamic>{};
  if (!oldShopSnap.exists) {
    stdout.writeln('WARNING: no shop/info doc found — proceeding with blank shop profile.');
  }

  // Determine the owner uid.
  final adminsSnap = await db.collection('admins').get();
  String? ownerUid = ownerUidArg;
  if (ownerUid == null) {
    for (final doc in adminsSnap.docs) {
      if ((doc.data()['role'] as String?) == 'superAdmin') {
        ownerUid = doc.id;
        break;
      }
    }
  }
  if (ownerUid == null) {
    stderr.writeln('ERROR: could not determine an owner uid. Pass --owner-uid=<uid> explicitly.');
    exit(1);
  }
  stdout.writeln('Owner uid: $ownerUid');

  // 2. Create the new shop doc.
  final shopRef = db.collection('shops').doc();
  final shopId = shopRef.id;
  await shopRef.set({
    'name': oldShopData['name'] ?? 'Saith Commission Shop',
    'ownerUid': ownerUid,
    'businessTypes': ['Commission Shop'],
    'phone': oldShopData['phone'] ?? '',
    'email': oldShopData['email'] ?? '',
    'address': oldShopData['address'] ?? '',
    'city': oldShopData['city'] ?? '',
    'ntn': oldShopData['ntn'] ?? '',
    'strn': oldShopData['strn'] ?? '',
    'defaultWeightUnit': '40kg',
    'defaultCommissionPercent': 0,
    'invoicePrefix': 'INV',
    'invoiceNextNumber': 1,
    'receiptPrefix': 'RCPT',
    'receiptNextNumber': 1,
    'currency': 'PKR',
    'status': 'active',
    'createdAt': FieldValue.serverTimestamp(),
  });
  stdout.writeln('Created shop $shopId');

  // 3. Seed default roles.
  const defaultRoles = <Map<String, dynamic>>[
    {
      'id': 'owner', 'name': 'Owner', 'isDefault': true,
      'permissions': [
        'view_dashboard','manage_products','manage_inventory','manage_customers',
        'manage_suppliers','create_sale','create_purchase','create_invoice',
        'edit_invoice','delete_invoice','void_invoice','create_receipt',
        'manage_expenses','view_ledger','view_analytics','view_reports',
        'export_data','manage_employees','manage_roles','manage_settings',
        'send_reminders',
      ],
    },
    {
      'id': 'manager', 'name': 'Manager', 'isDefault': true,
      'permissions': [
        'view_dashboard','manage_products','manage_inventory','manage_customers',
        'manage_suppliers','create_sale','create_purchase','create_invoice',
        'edit_invoice','view_ledger','view_analytics','view_reports',
        'export_data','send_reminders',
      ],
    },
    {
      'id': 'accountant', 'name': 'Accountant', 'isDefault': true,
      'permissions': [
        'view_dashboard','manage_customers','manage_suppliers','create_invoice',
        'create_receipt','manage_expenses','view_ledger','view_reports','export_data',
      ],
    },
    {
      'id': 'sales_staff', 'name': 'Sales Staff', 'isDefault': true,
      'permissions': ['view_dashboard','manage_customers','create_sale','create_invoice'],
    },
    {
      'id': 'inventory_staff', 'name': 'Inventory Staff', 'isDefault': true,
      'permissions': ['view_dashboard','manage_products','manage_inventory'],
    },
  ];
  for (final role in defaultRoles) {
    final roleId = role['id'] as String;
    await shopRef.collection('roles').doc(roleId).set({
      ...role,
      'shopId': shopId,
    }..remove('id'));
  }
  stdout.writeln('Seeded ${defaultRoles.length} default roles.');

  // 4. Create shop_members from existing admins.
  var memberCount = 0;
  for (final doc in adminsSnap.docs) {
    final data = doc.data();
    final oldRole = data['role'] as String? ?? 'staff';
    final roleId = _oldAdminRoleToNewRoleId[oldRole] ?? 'sales_staff';
    await db.collection('shop_members').add({
      'shopId': shopId,
      'uid': doc.id,
      'roleId': roleId,
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Keep the index doc used by Security Rules in sync.
    await db.collection('shop_members_index').doc('${doc.id}_$shopId').set({
      'uid': doc.id,
      'shopId': shopId,
      'roleId': roleId,
    });
    memberCount++;
  }
  stdout.writeln('Created $memberCount shop_members (+ index docs).');

  // 5. Stamp shopId onto existing shop-scoped collections.
  const collectionsToStamp = [
    'products', 'customers', 'suppliers', 'invoices', 'purchases', 'stock_history',
  ];
  for (final coll in collectionsToStamp) {
    final snap = await db.collection(coll).get();
    var batch = db.batch();
    var opCount = 0;
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'shopId': shopId});
      opCount++;
      if (opCount == 400) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) await batch.commit();
    stdout.writeln('Stamped shopId on ${snap.docs.length} docs in `$coll`.');
  }

  // 6. Rebuild ledger -> customer_ledger_entries / supplier_ledger_entries.
  // The old `ledger` collection's shape varies by how it was written
  // historically (see LedgerProvider/addLedgerEntry call sites) — this
  // migrates the common shape {customerId, type, amount, dateTime} and
  // computes a running balance per customer in chronological order.
  // Supplier-side ledger entries, if any exist under the same collection
  // with a `supplierId` field instead, are split out the same way.
  final oldLedgerSnap = await db.collection('ledger').orderBy('dateTime').get();
  final customerRunning = <String, double>{};
  final supplierRunning = <String, double>{};
  var customerLedgerCount = 0;
  var supplierLedgerCount = 0;

  for (final doc in oldLedgerSnap.docs) {
    final data = doc.data();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final isDebit = (data['type'] as String? ?? '').toLowerCase().contains('invoice')
        || (data['type'] as String? ?? '').toLowerCase().contains('sale');

    if (data['customerId'] != null) {
      final customerId = data['customerId'] as String;
      final prev = customerRunning[customerId] ?? 0;
      final next = isDebit ? prev + amount : prev - amount;
      customerRunning[customerId] = next;
      await db.collection('customer_ledger_entries').add({
        'shopId': shopId,
        'customerId': customerId,
        'type': data['type'] ?? 'adjustment',
        'debit': isDebit ? amount : 0,
        'credit': isDebit ? 0 : amount,
        'runningBalance': next,
        'referenceId': data['reference'],
        'date': data['dateTime'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      customerLedgerCount++;
    } else if (data['supplierId'] != null) {
      final supplierId = data['supplierId'] as String;
      final prev = supplierRunning[supplierId] ?? 0;
      final next = isDebit ? prev + amount : prev - amount;
      supplierRunning[supplierId] = next;
      await db.collection('supplier_ledger_entries').add({
        'shopId': shopId,
        'supplierId': supplierId,
        'type': data['type'] ?? 'adjustment',
        'debit': isDebit ? amount : 0,
        'credit': isDebit ? 0 : amount,
        'runningBalance': next,
        'referenceId': data['reference'],
        'date': data['dateTime'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      supplierLedgerCount++;
    }
  }
  stdout.writeln('Rebuilt ledger: $customerLedgerCount customer entries, '
      '$supplierLedgerCount supplier entries. '
      'MANUALLY VERIFY final running balances against the old `ledger` '
      'collection before relying on these for real accounting.');

  stdout.writeln('== Migration complete. shopId = $shopId ==');
  stdout.writeln('Old collections (shop/info, admins, ledger) were left '
      'untouched — remove them manually only after verification.');
}

String? _argValue(List<String> args, String name) {
  for (final a in args) {
    if (a.startsWith('--$name=')) return a.substring('--$name='.length);
  }
  return null;
}
