import 'package:email_validator/email_validator.dart';

class Validators {
  static String? requiredField(String? value, {String field = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final result = requiredField(value, field: 'Email');
    if (result != null) return result;
    if (!EmailValidator.validate(value!.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Use at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number';
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'Include at least one special character';
    }
    return null;
  }

  static String? confirmPassword(String? confirm, String password) {
    final result = requiredField(confirm, field: 'Confirm password');
    if (result != null) return result;
    if (confirm != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static int passwordStrengthScore(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return score;
  }
}
