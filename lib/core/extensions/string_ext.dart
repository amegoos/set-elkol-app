extension StringX on String {
  bool get isValidEmail {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  String get toSentenceCase {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  /// Formats number string with commas: "10000" -> "10,000"
  String get withCommas {
    final n = double.tryParse(this);
    if (n == null) return this;
    return n.toStringAsFixed(n == n.truncateToDouble() ? 0 : 2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }
}

extension DoubleX on double {
  String get toEgp => '${toStringAsFixed(2)} ج.م';
  String get toEgpEn => 'EGP ${toStringAsFixed(2)}';
}
