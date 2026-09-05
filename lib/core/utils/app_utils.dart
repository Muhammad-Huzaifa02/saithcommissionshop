import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// ── Input Validators ───────────────────────────────────────────────────────
class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v, {int minLen = 6}) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < minLen) return 'Password must be at least $minLen characters';
    return null;
  }

  static String? required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? positiveNumber(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName is required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n < 0)     return '$fieldName cannot be negative';
    return null;
  }

  static String? price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter a valid price greater than 0';
    return null;
  }

  static String? stockQty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Quantity is required';
    final n = double.tryParse(v);
    if (n == null || n < 0) return 'Enter a valid quantity';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? productName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Product name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    if (v.trim().length > 50) return 'Name must be under 50 characters';
    return null;
  }

  static String? customerName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (v.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }
}

// ── Security Utilities ─────────────────────────────────────────────────────
class SecurityUtils {
  /// One-way hash for passwords (SHA-256)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Sanitize user input — strip dangerous characters
  static String sanitize(String input) {
    return input.trim()
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\\', '');
  }

  /// Mask phone number for display: 0300-****-4567
  static String maskPhone(String phone) {
    if (phone.length < 4) return '****';
    return '${phone.substring(0, 4)}-****-${phone.substring(phone.length - 4)}';
  }

  /// Mask email for display: a***@gmail.com
  static String maskEmail(String email) {
    if (!email.contains('@')) return '****';
    final parts = email.split('@');
    final name  = parts[0];
    final masked = name.length > 1
        ? '${name[0]}${'*' * (name.length - 1)}'
        : '*';
    return '$masked@${parts[1]}';
  }

  /// Simple session token generator
  static String generateToken() {
    final now   = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(now);
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  /// Rate limiting tracker
  static final Map<String, List<DateTime>> _attempts = {};

  static bool isRateLimited(String key, {int maxAttempts = 5, int windowSeconds = 300}) {
    final now = DateTime.now();
    _attempts[key] ??= [];
    _attempts[key]!.removeWhere(
            (t) => now.difference(t).inSeconds > windowSeconds);
    _attempts[key]!.add(now);
    return _attempts[key]!.length > maxAttempts;
  }

  static void clearAttempts(String key) => _attempts.remove(key);
}

// ── Formatters ─────────────────────────────────────────────────────────────
class Fmt {
  static String currency(double v, {String symbol = 'PKR'}) {
    if (v >= 10000000) return '$symbol ${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '$symbol ${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '$symbol ${(v / 1000).toStringAsFixed(1)}K';
    return '$symbol ${v.toStringAsFixed(0)}';
  }

  static String date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static String dateTime(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inHours   < 1)  return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1)  return '${diff.inHours}h ago';
    if (diff.inDays    < 7)  return '${diff.inDays}d ago';
    return date(d);
  }

  static String kg(double v) => '${v.toStringAsFixed(0)} kg';
  static String bags(double v) => '${(v / 40).toStringAsFixed(0)} bags';
}

// ── Constants ──────────────────────────────────────────────────────────────
class AppConstants {
  static const int    maxLoginAttempts    = 5;
  static const int    sessionTimeout      = 30; // minutes
  static const int    minPasswordLength   = 6;
  static const double defaultReorderKg   = 200;
  static const int    maxProductNameLen  = 50;
  static const int    maxInvoicesPerPage = 20;
  static const String appVersion         = '2.0.0';
  static const String currency           = 'PKR';
}


// ── Page Transitions ───────────────────────────────────────────────────────
class PageTransitions {
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut));
        return ScaleTransition(
          scale: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

// ── Pakistan Formatter ─────────────────────────────────────────────────────
class PakistanFormatter {
  /// Format amount with Lakh/Crore
  static String formatPKR(double amount, {bool showSymbol = true}) {
    final symbol = showSymbol ? 'PKR ' : '';
    if (amount >= 10000000) return '$symbol${(amount / 10000000).toStringAsFixed(2)} Crore';
    if (amount >= 100000)   return '$symbol${(amount / 100000).toStringAsFixed(2)} Lakh';
    if (amount >= 1000)     return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  /// Format PKR with commas: 1,00,000
  static String formatPKRWithCommas(double amount) {
    final str = amount.toInt().toString();
    if (str.length <= 3) return 'PKR $str';
    final buf       = StringBuffer();
    buf.write(str.substring(str.length - 3));
    var remaining = str.substring(0, str.length - 3);
    while (remaining.length > 2) {
      buf.write(',');
      buf.write(remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) { buf.write(','); buf.write(remaining); }
    return 'PKR ${buf.toString().split('').reversed.join()}';
  }

  /// Normalize to +92 format
  static String normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('0'))  return '+92${phone.substring(1)}';
    if (phone.startsWith('92')) return '+$phone';
    if (!phone.startsWith('+')) return '+92$phone';
    return phone;
  }

  /// Validate Pakistani mobile number
  static bool isValidPhone(String phone) =>
      RegExp(r'^\+923[0-9]{9}$').hasMatch(normalizePhone(phone));

  /// DD/MM/YYYY
  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Time-based greeting
  static String getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Amount in words (Lakh/Crore)
  static String amountInWords(double amount) {
    if (amount >= 10000000) return 'PKR ${(amount / 10000000).toStringAsFixed(2)} Crore';
    if (amount >= 100000)   return 'PKR ${(amount / 100000).toStringAsFixed(2)} Lakh';
    if (amount >= 1000)     return 'PKR ${(amount / 1000).toStringAsFixed(1)}k';
    return 'PKR ${amount.toStringAsFixed(0)}';
  }
}