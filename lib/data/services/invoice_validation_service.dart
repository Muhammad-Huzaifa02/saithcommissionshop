import 'package:saithcommissionshop/data/models/invoice_models.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});
}

class InvoiceValidationService {
  static ValidationResult validate(InvoiceData invoice) {
    final errors = <String>[];

    if (invoice.customerName.trim().isEmpty) {
      errors.add('Customer name is required');
    }
    if (invoice.customerPhone.trim().isEmpty) {
      errors.add('Phone number is required');
    } else if (!isValidPakistaniPhone(invoice.customerPhone)) {
      errors.add('Enter a valid Pakistani phone number (e.g. 03XXXXXXXXX)');
    }
    if (invoice.products.isEmpty) {
      errors.add('Add at least one product');
    }
    for (var p in invoice.products) {
      if (p.quantity <= 0) {
        errors.add('${p.name}: Quantity cannot be zero');
      }
      if (p.pricePer40kg <= 0) {
        errors.add('${p.name}: Price is invalid');
      }
    }
    if (invoice.amountPaid < 0) {
      errors.add('Paid amount cannot be negative');
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  static bool isValidPakistaniPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'\s|-'), '');
    return RegExp(r'^(\+92|0092|0)[3][0-9]{9}$').hasMatch(normalized);
  }

  static bool isValidNTN(String ntn) =>
      RegExp(r'^\d{7}-\d$').hasMatch(ntn.trim());

  static bool isValidSTRN(String strn) =>
      RegExp(r'^\d{13}$').hasMatch(strn.replaceAll('-', ''));
}
