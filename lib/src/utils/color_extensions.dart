import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  String toHexCodeString() => ((((a * 255).round() & 0xFF) << 24) |
          ((r * 255).round() << 16) |
          ((g * 255).round() << 8) |
          (b * 255).round())
      .toRadixString(16)
      .padLeft(8, '0');
}
