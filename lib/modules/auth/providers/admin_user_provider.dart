import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saithcommissionshop/data/models/admin_user_model.dart';
import 'package:saithcommissionshop/data/services/firebase_services.dart';

class AdminUserProvider extends ChangeNotifier {
  AdminUser?  _currentUser;
  bool        _isLoaded    = false;
  bool        _needsSetup  = false;
  int         _failedAttempts = 0;
  DateTime?   _lockUntil;
  String?     _error;

  AdminUser? get currentUser    => _currentUser;
  bool       get isLoggedIn     => _currentUser != null;
  bool       get isLoaded       => _isLoaded;
  bool       get needsSetup     => _needsSetup;
  bool       get isLocked       => _lockUntil != null && DateTime.now().isBefore(_lockUntil!);
  int        get failedAttempts => _failedAttempts;
  String?    get error          => _error;

  String get lockMessage {
    if (_lockUntil == null) {
      return '';
    }
    final s = _lockUntil!.difference(DateTime.now()).inSeconds;
    return 'Too many attempts. Try again in ${s}s';
  }

  AdminUserProvider() { _checkExistingSession(); }

  // ── Check if already logged in ────────────────────────────────────────────
  Future<void> _checkExistingSession() async {
    try {
      // Check if any admin exists. If this fails (e.g. offline), 
      // we default to false (no setup needed) to avoid locking users out.
      final hasAdmins = await FirebaseService.hasAnyAdmin().timeout(
        const Duration(seconds: 5),
        onTimeout: () => true, // Assume admins exist if we can't check
      );
      _needsSetup = !hasAdmins;
      
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        await _loadAdminProfile(fbUser.uid);
      }
    } catch (e) {
      debugPrint('Error checking admin session: $e');
      _needsSetup = false; // Default to login screen on error
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadAdminProfile(String uid) async {
    final data = await FirebaseService.getAdminProfile(uid);
    if (data != null) {
      _currentUser = AdminUser(
        id:    uid,
        name:  data['name']  as String? ?? 'Admin',
        email: data['email'] as String? ?? '',
        role:  AdminRole.values.firstWhere(
              (r) => r.name == (data['role'] as String? ?? 'superAdmin'),
          orElse: () => AdminRole.staff,
        ),
      );
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    if (isLocked) {
      return false;
    }
    _error = null;
    try {
      final cred = await FirebaseService.signIn(email.trim(), password);
      await _loadAdminProfile(cred.user!.uid);

      if (_currentUser == null) {
        // Firebase account exists but no Firestore profile — create it
        _currentUser = AdminUser(
          id:    cred.user!.uid,
          name:  email.split('@').first,
          email: email.trim(),
          role:  AdminRole.superAdmin,
        );
        await FirebaseService.saveAdminProfile(cred.user!.uid, {
          'name':  _currentUser!.name,
          'email': _currentUser!.email,
          'role':  _currentUser!.role.name,
        });
      }

      _failedAttempts = 0;
      _lockUntil      = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _lockUntil      = DateTime.now().add(const Duration(minutes: 5));
        _failedAttempts = 0;
      }
      _error = _authError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ── First-time setup ──────────────────────────────────────────────────────
  Future<bool> setupFirstAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    _error = null;
    try {
      final cred = await FirebaseService.createUser(email.trim(), password);
      final uid  = cred.user!.uid;

      await FirebaseService.saveAdminProfile(uid, {
        'name':      name.trim(),
        'email':     email.trim(),
        'role':      AdminRole.superAdmin.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _currentUser = AdminUser(
        id:    uid,
        name:  name.trim(),
        email: email.trim(),
        role:  AdminRole.superAdmin,
      );
      _needsSetup = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ── Add staff ─────────────────────────────────────────────────────────────
  Future<bool> addStaff({
    required String    name,
    required String    email,
    required String    password,
    required AdminRole role,
  }) async {
    if (_currentUser?.role != AdminRole.superAdmin) {
      return false;
    }
    try {
      final cred = await FirebaseService.createUser(email.trim(), password);
      await FirebaseService.saveAdminProfile(cred.user!.uid, {
        'name':      name.trim(),
        'email':     email.trim(),
        'role':      role.name,
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy':   _currentUser!.id,
      });
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      notifyListeners();
      return false;
    }
  }

  // ── Remove staff ──────────────────────────────────────────────────────────
  Future<bool> removeStaff(String staffId) async {
    if (_currentUser?.role != AdminRole.superAdmin) {
      return false;
    }
    if (_currentUser?.id == staffId) {
      return false;
    }
    try {
      await FirebaseFirestore.instance.collection('admins').doc(staffId).delete();
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  // ── Change password ───────────────────────────────────────────────────────
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final user  = FirebaseAuth.instance.currentUser!;
      final cred  = EmailAuthProvider.credential(
          email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } catch (_) { return false; }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await FirebaseService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // ── All staff ─────────────────────────────────────────────────────────────
  List<AdminUser> get allStaff => [];

  Stream<List<AdminUser>> get staffStream =>
      FirebaseService.allAdminsStream().map((snap) => snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return AdminUser(
          id:    d.id,
          name:  data['name']  as String? ?? '',
          email: data['email'] as String? ?? '',
          role:  AdminRole.values.firstWhere(
                (r) => r.name == (data['role'] as String?),
            orElse: () => AdminRole.staff,
          ),
        );
      }).toList());

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':       return 'No account found with this email';
      case 'wrong-password':       return 'Incorrect password';
      case 'invalid-credential':   return 'Invalid email or password';
      case 'too-many-requests':    return 'Too many attempts. Please try later';
      case 'email-already-in-use': return 'Email already registered';
      case 'weak-password':        return 'Password must be at least 6 characters';
      case 'network-request-failed': return 'No internet connection';
      default:                     return 'Authentication failed. Please try again';
    }
  }
}
