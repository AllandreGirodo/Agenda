import 'package:flutter/services.dart';

class InternationalPhoneInputFormatter extends TextInputFormatter {
  static const String defaultDdi = '55';
  static const int defaultMaxLocalDigits = 11;
  static const int maxInternationalLocalDigits = 15;

  final String ddi;
  final int maxLocalDigits;
  final ValueChanged<bool>? onInvalidInputChanged;

  const InternationalPhoneInputFormatter({
    this.ddi = defaultDdi,
    this.maxLocalDigits = defaultMaxLocalDigits,
    this.onInvalidInputChanged,
  });

  static String normalizeDdi(String? value, {String fallback = defaultDdi}) {
    final digitsOnly = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return fallback;
    }
    return digitsOnly;
  }

  static int normalizeMaxLocalDigits(int? value, {int fallback = defaultMaxLocalDigits}) {
    final candidate = value ?? fallback;
    if (candidate <= 0) return fallback;
    return candidate;
  }

  static String localDigits(
    String value, {
    String ddi = defaultDdi,
    int maxLocalDigits = defaultMaxLocalDigits,
  }) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';

    final normalizedDdi = normalizeDdi(ddi);
    final normalizedMax = normalizeMaxLocalDigits(maxLocalDigits);

    var normalized = digitsOnly;
    if (normalized.length > normalizedMax && normalized.startsWith(normalizedDdi)) {
      normalized = normalized.substring(normalizedDdi.length);
    }

    if (normalized.length > normalizedMax) {
      normalized = normalized.substring(0, normalizedMax);
    }

    return normalized;
  }

  static String formatLocal(
    String value, {
    String ddi = defaultDdi,
    int maxLocalDigits = defaultMaxLocalDigits,
  }) {
    final normalizedDdi = normalizeDdi(ddi);
    final digits = localDigits(
      value,
      ddi: normalizedDdi,
      maxLocalDigits: maxLocalDigits,
    );
    if (digits.isEmpty) return '';

    // Mantem a mascara tradicional BR para DDI 55.
    if (normalizedDdi == defaultDdi) {
      return _formatBrazilianDigits(digits);
    }

    // Para demais DDIs, aplica agrupamento generico por blocos de 3.
    return _formatInternationalDigits(digits);
  }

  static String toE164(
    String value, {
    String ddi = defaultDdi,
    int maxLocalDigits = defaultMaxLocalDigits,
  }) {
    final normalizedDdi = normalizeDdi(ddi);
    final normalizedLocalDigits = localDigits(
      value,
      ddi: normalizedDdi,
      maxLocalDigits: maxLocalDigits,
    );
    if (normalizedLocalDigits.isEmpty) return '';
    return '+$normalizedDdi$normalizedLocalDigits';
  }

  static String formatWithDdi(
    String value, {
    String ddi = defaultDdi,
    int maxLocalDigits = defaultMaxLocalDigits,
    bool includePlusSign = true,
  }) {
    final normalizedDdi = normalizeDdi(ddi);
    final local = formatLocal(
      value,
      ddi: normalizedDdi,
      maxLocalDigits: maxLocalDigits,
    );
    if (local.isEmpty) return '';

    final prefix = includePlusSign ? '+$normalizedDdi' : normalizedDdi;
    return '$prefix $local';
  }

  static String _formatBrazilianDigits(String digits) {
    final buffer = StringBuffer();
    buffer.write('(');

    if (digits.length <= 2) {
      buffer.write(digits);
      return buffer.toString();
    }

    buffer.write(digits.substring(0, 2));
    buffer.write(') ');

    if (digits.length <= 7) {
      buffer.write(digits.substring(2));
      return buffer.toString();
    }

    if (digits.length <= 10) {
      buffer.write(digits.substring(2, 6));
      buffer.write('-');
      buffer.write(digits.substring(6));
      return buffer.toString();
    }

    buffer.write(digits.substring(2, 7));
    buffer.write('-');
    buffer.write(digits.substring(7));
    return buffer.toString();
  }

  static String _formatInternationalDigits(String digits) {
    if (digits.length <= 3) return digits;

    final groups = <String>[];
    var index = 0;
    while (index < digits.length) {
      final end = (index + 3 < digits.length) ? index + 3 : digits.length;
      groups.add(digits.substring(index, end));
      index = end;
    }

    return groups.join(' ');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final hasInvalidInput = RegExp(r'[^0-9()\-\s+]').hasMatch(newValue.text);
    onInvalidInputChanged?.call(hasInvalidInput);

    final formatted = formatLocal(
      newValue.text,
      ddi: ddi,
      maxLocalDigits: maxLocalDigits,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

@Deprecated('Use InternationalPhoneInputFormatter.')
class BrazilPhoneInputFormatter extends InternationalPhoneInputFormatter {
  const BrazilPhoneInputFormatter({
    super.onInvalidInputChanged,
  }) : super(
         ddi: InternationalPhoneInputFormatter.defaultDdi,
         maxLocalDigits: InternationalPhoneInputFormatter.defaultMaxLocalDigits,
       );
}