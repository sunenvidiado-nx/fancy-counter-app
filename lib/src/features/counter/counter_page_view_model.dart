import 'package:fancy_counter_app/src/utils/color_extensions.dart';
import 'package:fancy_counter_app/src/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mesh_gradient/mesh_gradient.dart';
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
  final colorsNotifier = ValueNotifier(<Color>[]);

  Timer? _debounceTimer;
  int _pendingCount = 0;

  void _loadCounter() {
    counterNotifier.value = _prefs.getInt(_counterKey) ?? 0;
  }

  void _loadColors() {
    final storedColorsString = _prefs.getString(_colorKey);

    if (storedColorsString == null || storedColorsString.isEmpty) {
      final newColors = _generateColors();
      colorsNotifier.value = newColors;
      _saveColors(newColors);
      return;
    }

    try {
      final loadedColors = storedColorsString
          .split(',')
          .map((colorString) => colorString.toColor())
          .toList();

      if (loadedColors.length != 4) {
        throw FormatException('Invalid number of colors');
      }

      colorsNotifier.value = loadedColors;
    } catch (_) {
      final newColors = _generateColors();
      colorsNotifier.value = newColors;
      _saveColors(newColors);
    }
  }

  void _saveColors(List<Color> colors) {
    final mergedColors = colors.map((c) => c.toHexCodeString()).join(',');

    _prefs.setString(_colorKey, mergedColors);
  }

  List<Color> _generateColors() {
    final baseHue = _random.nextDouble() * 360;
    final hueOffsets = [
      0.0,
      60 + _random.nextDouble() * 30, // analogous
      180 + _random.nextDouble() * 60, // split complement
      240 + _random.nextDouble() * 60, // triadic
    ];

    final colors = <Color>[];
    for (final offset in hueOffsets) {
      final hue = (baseHue + offset) % 360;
      colors.add(
        HSLColor.fromAHSL(
          1.0,
          hue,
          0.7 + _random.nextDouble() * 0.3, // saturation: 0.7-1.0
          0.3 + _random.nextDouble() * 0.5, // lightness: 0.3-0.8
        ).toColor(),
      );
    }

    return colors..shuffle();
  }

  List<MeshGradientPoint> createGradientPoints() {
    final colors = colorsNotifier.value;
    final basePositions = [
      [-0.5, -0.5], // far outside corners for dramatic spread
      [0.3, -0.3],
      [0.7, 1.3],
      [1.5, 1.5],
    ];

    return List.generate(4, (index) {
      final randomOffset = 0.4;
      final x =
          basePositions[index][0] + (_random.nextDouble() - 0.5) * randomOffset;
      final y =
          basePositions[index][1] + (_random.nextDouble() - 0.5) * randomOffset;

      return MeshGradientPoint(
        position: Offset(
          x.clamp(-0.8, 1.8), // allow points far outside for smooth edges
          y.clamp(-0.8, 1.8),
        ),
        color: colors[index],
      );
    });
  }

  List<AnimationSequence> createGradientAnimationSequences(
      {bool isColorChange = false}) {
    final colors = colorsNotifier.value;
    final targetPositions = isColorChange
        ? [
            // Quick color change positions
            [
              -0.5 + _random.nextDouble() * 0.4,
              -0.5 + _random.nextDouble() * 0.4
            ],
            [
              0.4 + _random.nextDouble() * 0.6,
              -0.3 + _random.nextDouble() * 0.6
            ],
            [
              -0.3 + _random.nextDouble() * 0.6,
              0.7 + _random.nextDouble() * 0.6
            ],
            [
              1.5 + _random.nextDouble() * 0.4,
              1.5 + _random.nextDouble() * 0.4
            ],
          ]
        : [
            // Continuous movement positions
            [
              -0.3 + _random.nextDouble() * 1.6,
              -0.3 + _random.nextDouble() * 1.6
            ],
            [
              -0.3 + _random.nextDouble() * 1.6,
              -0.3 + _random.nextDouble() * 1.6
            ],
            [
              -0.3 + _random.nextDouble() * 1.6,
              -0.3 + _random.nextDouble() * 1.6
            ],
            [
              -0.3 + _random.nextDouble() * 1.6,
              -0.3 + _random.nextDouble() * 1.6
            ],
          ];

    // Different curves for varied movement
    final curves = isColorChange
        ? [
            Curves.easeInOutSine,
            Curves.easeInOutSine,
            Curves.easeInOutSine,
            Curves.easeInOutSine,
          ]
        : [
            Curves.linear,
            Curves.linear,
            Curves.linear,
            Curves.linear,
          ];

    return List.generate(4, (index) {
      final targetX = targetPositions[index][0];
      final targetY = targetPositions[index][1];

      return AnimationSequence(
        pointIndex: index,
        newPoint: MeshGradientPoint(
          position: Offset(targetX, targetY),
          color: colors[index],
        ),
        interval: Interval(0, 1, curve: curves[index]),
      );
    });
  }

  void increment() {
    final newCount = counterNotifier.value + 1;

    counterNotifier.value = newCount;
    _pendingCount = newCount;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _prefs.setInt(_counterKey, _pendingCount);
    });

    if (newCount % 10 == 0) {
      _changeColors();
    }
  }

  void _changeColors() {
    final newColors = _generateColors();
    colorsNotifier.value = newColors;
    _saveColors(newColors);
  }

  Future<void> reset() async {
    counterNotifier.value = 0;
    await _prefs.setInt(_counterKey, 0);
  }

  void dispose() {
    counterNotifier.dispose();
    colorsNotifier.dispose();
    _debounceTimer?.cancel();
  }
}
