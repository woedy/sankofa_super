import 'package:flutter/services.dart';

class GhanaPhoneNumberFormatter extends TextInputFormatter {
  const GhanaPhoneNumberFormatter();

  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  static String formatForDisplay(String input) {
    final digits = digitsOnly(input);
    if (digits.isEmpty) {
      return '';
    }

    final truncated = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buffer = StringBuffer();

    for (var i = 0; i < truncated.length; i++) {
      buffer.write(truncated[i]);
      if (i == 1 || i == 4) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatForDisplay(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
