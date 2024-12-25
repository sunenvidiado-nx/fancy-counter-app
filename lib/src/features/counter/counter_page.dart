import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

import 'counter_page_view_model.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
    with TickerProviderStateMixin {
  late final MeshGradientController _gradientController;
  late final AnimationController _textAnimationController;
  final _random = GetIt.I<Random>();
  final _viewModel = GetIt.I<CounterPageViewModel>();

  @override
  void initState() {
    super.initState();
    _textAnimationController = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    _textAnimationController.forward(from: 0);
    _gradientController = MeshGradientController(
      points: _createRandomGradientPoints(_viewModel.colorsNotifier.value),
      vsync: this,
    );
    _viewModel.colorsNotifier.addListener(() {
      _animateGradient(_gradientController, _viewModel.colorsNotifier.value);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _textAnimationController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackground(),
        _buildCounterBody(),
      ],
    );
  }

  List<MeshGradientPoint> _createRandomGradientPoints(List<Color> colors) {
    return [
      MeshGradientPoint(
        position: Offset(
            0.2 + _random.nextDouble() * 0.2, 0.3 + _random.nextDouble() * 0.4),
        color: colors[0],
      ),
      MeshGradientPoint(
        position: Offset(
            0.5 + _random.nextDouble() * 0.3, 0.5 + _random.nextDouble() * 0.4),
        color: colors[1],
      ),
      MeshGradientPoint(
        position: Offset(
            0.8 + _random.nextDouble() * 0.2, 0.6 + _random.nextDouble() * 0.3),
        color: colors[2],
      ),
      MeshGradientPoint(
        position: Offset(
            0.5 + _random.nextDouble() * 0.3, 0.9 + _random.nextDouble() * 0.1),
        color: colors[3],
      ),
    ];
  }

  void _animateGradient(MeshGradientController controller, List<Color> colors) {
    controller.animateSequence(
      duration: const Duration(seconds: 5),
      sequences: [
        AnimationSequence(
          pointIndex: 0,
          newPoint: MeshGradientPoint(
            position: Offset(0.1 + _random.nextDouble() * 0.8,
                0.1 + _random.nextDouble() * 0.8),
            color: colors[0],
          ),
          interval: const Interval(0, 0.25),
        ),
        AnimationSequence(
          pointIndex: 1,
          newPoint: MeshGradientPoint(
            position: Offset(0.1 + _random.nextDouble() * 0.8,
                0.1 + _random.nextDouble() * 0.8),
            color: colors[1],
          ),
          interval: const Interval(0.25, 0.5),
        ),
        AnimationSequence(
          pointIndex: 2,
          newPoint: MeshGradientPoint(
            position: Offset(0.1 + _random.nextDouble() * 0.8,
                0.1 + _random.nextDouble() * 0.8),
            color: colors[2],
          ),
          interval: const Interval(0.5, 0.75),
        ),
        AnimationSequence(
          pointIndex: 3,
          newPoint: MeshGradientPoint(
            position: Offset(0.1 + _random.nextDouble() * 0.8,
                0.1 + _random.nextDouble() * 0.8),
            color: colors[3],
          ),
          interval: const Interval(0.75, 1),
        ),
      ],
    );
  }

  Widget _buildBackground() {
    return ValueListenableBuilder(
      valueListenable: _viewModel.colorsNotifier,
      builder: (context, colors, _) {
        return SizedBox.expand(
          child: MeshGradient(
            controller: _gradientController,
            options: MeshGradientOptions(),
          ),
        );
      },
    );
  }

  Widget _buildCounterBody() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: Colors.black45,
        onRefresh: _viewModel.reset,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _viewModel.increment();
            _textAnimationController.forward(from: 0);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: _buildCountText(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountText() {
    return ValueListenableBuilder(
      valueListenable: _viewModel.counterNotifier,
      builder: (context, count, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AnimatedBuilder(
              animation: _textAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (0.12 * _textAnimationController.value),
                  child: AutoSizeText(
                    count < 10 ? '0$count' : '$count',
                    wrapWords: false,
                    style: TextStyle(
                      fontSize: 200,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
