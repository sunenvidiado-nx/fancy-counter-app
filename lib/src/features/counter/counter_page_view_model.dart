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

  // Generate cache keys here: http://bit.ly/random-strings-generator
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

  // Calculate color difference using HSL values
  double _getColorDifference(HSLColor a, HSLColor b) {
    // Weight hue differences more heavily to avoid similar colors
    double hueDiff = (a.hue - b.hue).abs();
    if (hueDiff > 180) hueDiff = 360 - hueDiff;

    // Normalize differences to 0-1 range
    hueDiff /= 180;
    final satDiff = (a.saturation - b.saturation).abs();
    final lightDiff = (a.lightness - b.lightness).abs();

    // Weight hue more heavily in the difference calculation
    return hueDiff * 0.7 + satDiff * 0.15 + lightDiff * 0.15;
  }

  // Generate a new hue that's different from previous hues
  double _generateDistinctHue(List<double> previousHues) {
    double hue;
    int attempts = 0;
    const minHueDifference = 30.0; // Minimum difference in degrees

    do {
      hue = _random.nextDouble() * 360;
      attempts++;

      // Skip the usual green and purple ranges more aggressively
      if ((hue >= 90 && hue <= 150) || (hue >= 270 && hue <= 330)) {
        continue;
      }

      // Check if this hue is different enough from previous hues
      bool isDifferentEnough = previousHues.every((prevHue) {
        double diff = (hue - prevHue).abs();
        if (diff > 180) diff = 360 - diff;
        return diff >= minHueDifference;
      });

      if (isDifferentEnough || attempts > 50) {
        return hue;
      }
    } while (attempts <= 50);

    return hue;
  }

  List<Color> _generateColors() {
    final previousColors =
        colorsNotifier.value.map((c) => HSLColor.fromColor(c)).toList();
    final newHues = <double>[];
    final newColors = <Color>[];

    for (int i = 0; i < 4; i++) {
      var hue = _generateDistinctHue(newHues);
      newHues.add(hue);

      // Vary saturation and lightness based on position
      HSLColor newColor;
      switch (i) {
        case 0: // Near-white
          newColor = HSLColor.fromAHSL(1.0, hue, 0.15, 0.95);
          break;
        case 1: // Mid-tone
          newColor = HSLColor.fromAHSL(
              1.0,
              hue,
              0.7 + _random.nextDouble() * 0.2,
              0.5 + _random.nextDouble() * 0.1);
          break;
        case 2: // Dark
          newColor = HSLColor.fromAHSL(
              1.0,
              hue,
              0.8 + _random.nextDouble() * 0.2,
              0.3 + _random.nextDouble() * 0.1);
          break;
        case 3: // Bright accent
          newColor = HSLColor.fromAHSL(
              1.0,
              hue,
              0.85 + _random.nextDouble() * 0.15,
              0.6 + _random.nextDouble() * 0.1);
          break;
        default:
          newColor = HSLColor.fromAHSL(1.0, hue, 0.8, 0.5);
      }

      // Check if this color is different enough from previous colors
      if (previousColors.isNotEmpty) {
        bool isTooSimilar = previousColors
            .any((prevColor) => _getColorDifference(newColor, prevColor) < 0.3);

        // If too similar, adjust the hue slightly
        if (isTooSimilar) {
          hue = (hue + 30 + _random.nextDouble() * 30) % 360;
          newColor = HSLColor.fromAHSL(
              1.0, hue, newColor.saturation, newColor.lightness);
        }
      }

      newColors.add(newColor.toColor());
    }

    return newColors..shuffle();
  }

  List<MeshGradientPoint> createGradientPoints() {
    final colors = colorsNotifier.value;

    // Position points in a circle
    final angles =
        List.generate(4, (index) => index * (pi / 2)); // 90 degree spacing
    final radius = 0.7; // Distance from center

    final basePositions = angles.map((angle) {
      return [
        0.5 + cos(angle) * radius, // Center X + radius * cos(angle)
        0.5 + sin(angle) * radius, // Center Y + radius * sin(angle)
      ];
    }).toList();

    return List.generate(4, (index) {
      final randomOffset = 0.15;
      final x =
          basePositions[index][0] + (_random.nextDouble() - 0.5) * randomOffset;
      final y =
          basePositions[index][1] + (_random.nextDouble() - 0.5) * randomOffset;

      return MeshGradientPoint(
        position: Offset(
          x.clamp(-0.3, 1.3),
          y.clamp(-0.3, 1.3),
        ),
        color: colors[index],
      );
    });
  }

  List<AnimationSequence> createGradientAnimationSequences({
    bool isColorChange = false,
  }) {
    final colors = colorsNotifier.value;
    final isClockwise = _random.nextBool(); // Randomly choose direction
    final radius = 0.7; // Same radius as base positions

    // Calculate current angles of points from current positions
    final points = createGradientPoints();
    final currentPoints = List.generate(4, (index) {
      return [
        colors[index],
        atan2(
          points[index].position.dy - 0.5, // Relative to center Y
          points[index].position.dx - 0.5, // Relative to center X
        )
      ];
    });

    // Sort points by current angle to maintain relative positions
    currentPoints.sort((a, b) => (a[1] as double).compareTo(b[1] as double));

    // Generate target angles with rotation
    final rotationAmount =
        _random.nextDouble() * (pi / 4) + (pi / 6); // 30-75 degrees
    final targetPositions = List.generate(4, (index) {
      final currentAngle = currentPoints[index][1] as double;
      final targetAngle = isClockwise
          ? currentAngle + rotationAmount
          : currentAngle - rotationAmount;

      return [
        0.5 + cos(targetAngle) * radius + (_random.nextDouble() - 0.5) * 0.15,
        0.5 + sin(targetAngle) * radius + (_random.nextDouble() - 0.5) * 0.15,
      ];
    });

    final curves = [
      Curves.easeInOutCubic,
      Curves.easeInOutCubic,
      Curves.easeInOutCubic,
      Curves.easeInOutCubic,
    ];

    // Match colors with their new positions maintaining the order
    return List.generate(4, (index) {
      return AnimationSequence(
        pointIndex: colors.indexOf(currentPoints[index][0] as Color),
        newPoint: MeshGradientPoint(
          position: Offset(
            targetPositions[index][0],
            targetPositions[index][1],
          ),
          color: currentPoints[index][0] as Color,
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
