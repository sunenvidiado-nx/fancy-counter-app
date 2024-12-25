import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';

class CounterPageViewModel {
  CounterPageViewModel(this._prefs, this._random) {
    _loadCounter();
    _loadColors();
  }

  final SharedPreferencesWithCache _prefs;
  final Random _random;

  // http://bit.ly/random-strings-generator
  static const _counterKey = 'Z01CGxdl8KtF';
  static const _colorKey = 's36NCAFQuToE';

  final counterNotifier = ValueNotifier(0);
  final colorsNotifier = ValueNotifier<List<Color>>([]);

  Timer? _debounceTimer;
  int _pendingCount = 0;

  void _loadCounter() {
    counterNotifier.value = _prefs.getInt(_counterKey) ?? 0;
  }

  void _loadColors() {
    final storedColorsString = _prefs.getString(_colorKey);

    if (storedColorsString == null || storedColorsString.isEmpty) {
      colorsNotifier.value = _generateColors();
    }

    try {
      colorsNotifier.value = storedColorsString!.split(',').map((colorString) {
        final paddedColor = colorString.padLeft(6, '0');
        final fullColorHex = 'ff$paddedColor';
        return Color(int.parse(fullColorHex, radix: 16));
      }).toList();
    } catch (_) {
      colorsNotifier.value = _generateColors();
    }
  }

  List<Color> _generateColors() {
    return [
      Color.fromRGBO(
        150 + _random.nextInt(106),
        150 + _random.nextInt(106),
        150 + _random.nextInt(106),
        1.0,
      ),
      Color.fromRGBO(
        150 + _random.nextInt(106),
        150 + _random.nextInt(106),
        150 + _random.nextInt(106),
        1.0,
      ),
      Color.fromRGBO(
        150 + _random.nextInt(106),
        150 + _random.nextInt(106),
        150 + _random.nextInt(106),
        1.0,
      ),
      Colors.white,
    ]..shuffle();
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
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _prefs.setInt(_counterKey, _pendingCount);
    });

    if (newCount % 20 == 0) _changeColors();
  }

  void _changeColors() {
    colorsNotifier.value = _generateColors();

    _prefs.setString(
      _colorKey,
      colorsNotifier.value.map((color) {
        // Convert color to hex
        return ((color.r * 255).toInt().toRadixString(16).padLeft(2, '0')) +
            ((color.g * 255).toInt().toRadixString(16).padLeft(2, '0')) +
            ((color.b * 255).toInt().toRadixString(16).padLeft(2, '0'));
      }).join(','),
    );
  }

  Future<void> reset() async {
    counterNotifier.value = 0;
    colorsNotifier.value = _generateColors();
    _pendingCount = 0;
    _debounceTimer?.cancel();

    await Future.wait([
      _prefs.remove(_counterKey),
      _prefs.remove(_colorKey),
    ]);
  }

  void dispose() {
    _debounceTimer?.cancel();
    counterNotifier.dispose();
    colorsNotifier.dispose();
  }
}
