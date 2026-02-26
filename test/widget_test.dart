import 'package:flutter_test/flutter_test.dart';

import 'package:auth_app/core/utils/validators.dart';

void main() {
  group('Validators.password', () {
    test('rejects weak passwords', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('alllowercase1!'), isNotNull);
      expect(Validators.password('ALLUPPERCASE1!'), isNotNull);
      expect(Validators.password('NoNumber!'), isNotNull);
      expect(Validators.password('NoSpecial123'), isNotNull);
    });

    test('accepts strong password', () {
      expect(Validators.password('StrongPass1!'), isNull);
      expect(
        Validators.passwordStrengthScore('StrongPass1!'),
        greaterThanOrEqualTo(4),
      );
    });
  });
}
