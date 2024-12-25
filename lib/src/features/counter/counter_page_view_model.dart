import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';

class CounterPageViewModel {
  CounterPageViewModel(this._prefs) {
    _loadCounter();
    _loadColor();
  }

  final SharedPreferencesWithCache _prefs;

  // http://bit.ly/random-strings-generator
  static const _counterKey = 'Z01CGxdl8KtF';
  static const _colorKey = 's36NCAFQuToE';

  final counterNotifier = ValueNotifier(0);
  final colorNotifier = ValueNotifier(Colors.white);

  Timer? _debounceTimer;
  int _pendingCount = 0;

  void _loadCounter() {
    counterNotifier.value = _prefs.getInt(_counterKey) ?? 0;
  }

  void _loadColor() {
    final storedColor = _prefs.getString(_colorKey);

    if (storedColor == null) {
      colorNotifier.value = Colors.white;
      return;
    }

    try {
      final paddedColor = storedColor.padLeft(6, '0');
      final fullColorHex = 'ff$paddedColor';
      colorNotifier.value = Color(int.parse(fullColorHex, radix: 16));
    } catch (e) {
      colorNotifier.value = Colors.white;
    }
  }

  /// Increment the counter.
  ///
  /// If the count is divisible by 10, change the background color.
  ///
  /// A debounce timer is used to prevent the counter from being cached too often.
  void increment() {
    final newCount = counterNotifier.value + 1;
    counterNotifier.value = newCount;
    _pendingCount = newCount;

    // Cancel existing timer
    _debounceTimer?.cancel();

    // Start new debounce timer
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _prefs.setInt(_counterKey, _pendingCount);
    });

    if (newCount % 10 == 0) _changeColor();
  }

  void _changeColor() {
    final random = Random();
    colorNotifier.value = Color.fromRGBO(
      220 + random.nextInt(36),
      220 + random.nextInt(36),
      220 + random.nextInt(36),
      1.0,
    );

    final colorString = ((colorNotifier.value.r * 255)
            .toInt()
            .toRadixString(16)
            .padLeft(2, '0')) +
        ((colorNotifier.value.g * 255)
            .toInt()
            .toRadixString(16)
            .padLeft(2, '0')) +
        ((colorNotifier.value.b * 255)
            .toInt()
            .toRadixString(16)
            .padLeft(2, '0'));

    _prefs.setString(_colorKey, colorString);
  }

  Future<void> reset() async {
    counterNotifier.value = 0;
    _pendingCount = 0;
    _debounceTimer?.cancel();
    colorNotifier.value = Colors.white;

    await Future.wait([
      _prefs.remove(_counterKey),
      _prefs.remove(_colorKey),
    ]);
  }

  void dispose() {
    _debounceTimer?.cancel();
    counterNotifier.dispose();
    colorNotifier.dispose();
  }
}
