import 'package:flutter_test/flutter_test.dart';
import 'package:set_elkol_app/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('isValidEmail returns true for valid email address', () {
      expect(Validators.isValidEmail('test@example.com'), isTrue);
      expect(Validators.isValidEmail('user.name@domain.co.eg'), isTrue);
    });

    test('isValidEmail returns false for invalid email', () {
      expect(Validators.isValidEmail('invalid-email'), isFalse);
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('test@'), isFalse);
    });

    test('isValidEgyptianPhone returns true for valid Egyptian phone numbers', () {
      expect(Validators.isValidEgyptianPhone('01012345678'), isTrue);
      expect(Validators.isValidEgyptianPhone('01198765432'), isTrue);
      expect(Validators.isValidEgyptianPhone('01234567890'), isTrue);
      expect(Validators.isValidEgyptianPhone('01555555555'), isTrue);
    });

    test('isValidEgyptianPhone returns false for invalid phone numbers', () {
      expect(Validators.isValidEgyptianPhone('123456'), isFalse);
      expect(Validators.isValidEgyptianPhone('01912345678'), isFalse);
      expect(Validators.isValidEgyptianPhone('abc'), isFalse);
    });

    test('isPasswordValid enforces minimum length', () {
      expect(Validators.isPasswordValid('123456'), isTrue);
      expect(Validators.isPasswordValid('12345'), isFalse);
    });

    test('isValidEgyptianMobileNumber supports various input formats', () {
      expect(Validators.isValidEgyptianMobileNumber('01012345678'), isTrue);
      expect(Validators.isValidEgyptianMobileNumber('1012345678'), isTrue);
      expect(Validators.isValidEgyptianMobileNumber('+201012345678'), isTrue);
      expect(Validators.isValidEgyptianMobileNumber('201012345678'), isTrue);
      expect(Validators.isValidEgyptianMobileNumber('01234567890'), isTrue);
      expect(Validators.isValidEgyptianMobileNumber('12345'), isFalse);
      expect(Validators.isValidEgyptianMobileNumber('01912345678'), isFalse);
    });

    test('formatEgyptianPhoneForSupabase converts properly to E.164', () {
      expect(Validators.formatEgyptianPhoneForSupabase('01012345678'), equals('+201012345678'));
      expect(Validators.formatEgyptianPhoneForSupabase('1012345678'), equals('+201012345678'));
      expect(Validators.formatEgyptianPhoneForSupabase('+201012345678'), equals('+201012345678'));
      expect(Validators.formatEgyptianPhoneForSupabase('201012345678'), equals('+201012345678'));
    });
  });
}
