import 'package:flutter/material.dart';

// ============================================================
// PAGE TRANSITIONS
// ============================================================
class PageTransitions {
  static Route slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route slideFromBottom(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  static Route fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route scaleTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeInOut));
        return ScaleTransition(
          scale: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

// ============================================================
// PAKISTAN FORMATTER - Currency, Phone, etc.
// ============================================================
class PakistanFormatter {
  /// Format amount as PKR with Pakistani number system
  /// Handles Lakh and Crore
  static String formatPKR(double amount, {bool showSymbol = true}) {
    final symbol = showSymbol ? 'PKR ' : '';
    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(2)} Crore';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(2)} Lakh';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  /// Format PKR with commas (e.g., 1,00,000)
  static String formatPKRWithCommas(double amount) {
    final int intAmount = amount.toInt();
    final String str = intAmount.toString();
    if (str.length <= 3) return 'PKR $str';

    // Pakistani comma format: last 3, then groups of 2
    StringBuffer result = StringBuffer();
    result.write(str.substring(str.length - 3));
    String remaining = str.substring(0, str.length - 3);
    while (remaining.length > 2) {
      result.write(',');
      result.write(remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      result.write(',');
      result.write(remaining);
    }
    return 'PKR ${result.toString().split('').reversed.join()}';
  }

  /// Normalize Pakistani phone number to +92 format
  static String normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('0')) return '+92${phone.substring(1)}';
    if (phone.startsWith('92')) return '+$phone';
    if (!phone.startsWith('+')) return '+92$phone';
    return phone;
  }

  /// Validate Pakistani phone number
  static bool isValidPhone(String phone) {
    final normalized = normalizePhone(phone);
    return RegExp(r'^\+923[0-9]{9}$').hasMatch(normalized);
  }

  /// Format date in Pakistani style (DD/MM/YYYY)
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Get Pakistani greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Convert amount to words in English (Lakh/Crore style)
  static String amountInWords(double amount) {
    if (amount >= 10000000) {
      final crore = (amount / 10000000).toStringAsFixed(2);
      return 'PKR $crore Crore';
    }
    if (amount >= 100000) {
      final lakh = (amount / 100000).toStringAsFixed(2);
      return 'PKR $lakh Lakh';
    }
    if (amount >= 1000) {
      final hazar = (amount / 1000).toStringAsFixed(1);
      return 'PKR $hazar k';
    }
    return 'PKR ${amount.toStringAsFixed(0)}';
  }
}