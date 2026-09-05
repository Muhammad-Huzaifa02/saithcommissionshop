import 'dart:async';

enum PaymentStatus { success, pending, failed }

class PaymentResponse {
  final PaymentStatus status;
  final String transactionId;
  final String message;

  PaymentResponse({
    required this.status,
    required this.transactionId,
    required this.message,
  });
}

class PaymentService {
  /// Simulates a payment processing with a gateway (JazzCash, Easypaisa, etc.)
  static Future<PaymentResponse> processPayment({
    required String method,
    required double amount,
    required String customerPhone,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Random success/failure for simulation
    // In real app, this would hit an API endpoint
    final isSuccess = amount > 0; 
    
    if (isSuccess) {
      return PaymentResponse(
        status: PaymentStatus.success,
        transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        message: 'Payment of PKR $amount via $method was successful.',
      );
    } else {
      return PaymentResponse(
        status: PaymentStatus.failed,
        transactionId: '',
        message: 'Payment failed. Please try again.',
      );
    }
  }

  static bool isDigitalMethod(String method) {
    return ['JazzCash', 'Easypaisa', 'Bank Transfer'].contains(method);
  }
}

