/// Application-wide validators for form fields.
abstract final class AppValidators {
  AppValidators._();

  // ── Name ─────────────────────────────────────────────────────────────────

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم قصير جداً';
    }
    return null;
  }

  // ── Email ────────────────────────────────────────────────────────────────

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[\w.+\-]+@([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  // ── Phone ────────────────────────────────────────────────────────────────

  /// Validates Egyptian mobile phone numbers (01x format, 11 digits).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الموبايل مطلوب';
    }
    if (!isValidEgyptianPhone(value.trim())) {
      return 'رقم الموبايل غير صحيح — لازم يبدأ بـ 01 ويكون 11 رقم';
    }
    return null;
  }

  // ── Password ─────────────────────────────────────────────────────────────

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة السر مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة السر لازم تكون 8 حروف على الأقل';
    }
    return null;
  }

  // ── Confirm Password ─────────────────────────────────────────────────────

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'تأكيد كلمة السر مطلوب';
    }
    if (value != password) {
      return 'كلمتا السر غير متطابقتين';
    }
    return null;
  }

  // ── Price ────────────────────────────────────────────────────────────────

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'السعر مطلوب';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'السعر لازم يكون رقم صحيح';
    }
    if (parsed < 0) {
      return 'السعر لازم يكون أكبر من صفر';
    }
    return null;
  }

  // ── Quantity ─────────────────────────────────────────────────────────────

  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الكمية مطلوبة';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'الكمية لازم تكون عدد صحيح';
    }
    if (parsed < 0) {
      return 'الكمية لازم تكون صفر أو أكثر';
    }
    return null;
  }

  // ── Generic not-empty ────────────────────────────────────────────────────

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  // ── Helper predicates ────────────────────────────────────────────────────

  /// Returns true if valid email format.
  static bool isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final emailRegex = RegExp(r'^[\w.+\-]+@([a-zA-Z0-9\-]+\.)+[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(value.trim());
  }

  /// Returns true if password meets minimum length (6+ chars).
  static bool isPasswordValid(String? value) {
    if (value == null) return false;
    return value.length >= 6;
  }

  /// Returns true for valid Egyptian mobile numbers starting with 010, 011,
  /// 012, or 015 and exactly 11 digits long.
  static bool isValidEgyptianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s|-'), '');
    return RegExp(r'^01[0125]\d{8}$').hasMatch(cleaned);
  }

  /// Validates Egyptian mobile phone number in various formats:
  /// - 01012345678 (11 digits local)
  /// - 1012345678 (10 digits without leading 0)
  /// - +201012345678 (E.164 international)
  /// - 201012345678 (12 digits)
  static bool isValidEgyptianMobileNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^01[0125]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^1[0125]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^\+201[0125]\d{8}$').hasMatch(cleaned)) return true;
    if (RegExp(r'^201[0125]\d{8}$').hasMatch(cleaned)) return true;
    return false;
  }

  /// Formats Egyptian mobile phone input into E.164 (+201xxxxxxxxx).
  static String formatEgyptianPhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+20')) return cleaned;
    if (cleaned.startsWith('20')) return '+$cleaned';
    if (cleaned.startsWith('0020')) return '+${cleaned.substring(2)}';
    if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);
    return '+20$cleaned';
  }

  static String formatEgyptianPhoneForSupabase(String input) {
    return formatEgyptianPhone(input);
  }

  /// Returns true if the file extension is an allowed image format.
  static bool isValidImageFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }
}

/// Backwards compatibility alias for AppValidators
typedef Validators = AppValidators;
