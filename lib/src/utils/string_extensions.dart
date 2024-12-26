import 'package:flutter/material.dart';

extension StringColorExtension on String {
  Color toColor() {
    final hexString = startsWith('#') ? substring(1) : this;
    if (hexString.length != 6 && hexString.length != 8) {
      throw FormatException('Invalid hex color string: $this');
    }
    final hexValue = int.parse(
        hexString.length == 8 ? hexString : 'ff$hexString',
        radix: 16);
    return Color(hexValue);
  }
}
