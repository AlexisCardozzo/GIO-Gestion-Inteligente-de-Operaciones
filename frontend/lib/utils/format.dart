import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

String formatMiles(num value) {
  final formato = NumberFormat("#,##0", "es_ES");
  return formato.format(value);
}

num parseNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll('.', '')) ?? 0;
  return 0;
}

class MilesInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String clean = newValue.text.replaceAll('.', '');
    if (clean.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(clean);
    if (number == null) return newValue.copyWith(text: '');
    final formatted = formatMiles(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
} 