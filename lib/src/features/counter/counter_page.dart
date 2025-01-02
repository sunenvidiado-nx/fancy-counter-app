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
  final _viewModel = GetIt.I<CounterPageViewModel>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupColorListener();
  }

  void _initializeControllers() {
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..forward(from: 0);

    _gradientController = MeshGradientController(
      points: _viewModel.createGradientPoints(),
      vsync: this,
    );

    _startContinuousAnimation();
  }

  void _startContinuousAnimation() {
    Future<void> animate() async {
      while (mounted) {
        await _gradientController.animateSequence(
          duration: const Duration(seconds: 16),
          sequences:
              _viewModel.createGradientAnimationSequences(isColorChange: false),
        );
      }
    }

    animate();
  }

  void _setupColorListener() {
    _viewModel.colorsNotifier.addListener(() {
      _gradientController
          .animateSequence(
            duration: const Duration(seconds: 3),
            sequences: _viewModel.createGradientAnimationSequences(
                isColorChange: true),
          )
          .then((_) => _startContinuousAnimation());
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
        _GradientBackground(_gradientController),
        _CounterContent(
          viewModel: _viewModel,
          textAnimationController: _textAnimationController,
        ),
      ],
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground(this.controller);

  final MeshGradientController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: MeshGradient(
        controller: controller,
        options: MeshGradientOptions(),
      ),
    );
  }
}

class _CounterContent extends StatelessWidget {
  const _CounterContent({
    required this.viewModel,
    required this.textAnimationController,
  });

  final CounterPageViewModel viewModel;
  final AnimationController textAnimationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: Colors.black45,
        onRefresh: () async {
          await viewModel.reset();
          textAnimationController.forward(from: 0);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            viewModel.increment();
            textAnimationController.forward(from: 0);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: _CounterDisplay(
                  counterNotifier: viewModel.counterNotifier,
                  textAnimationController: textAnimationController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterDisplay extends StatelessWidget {
  const _CounterDisplay({
    required this.counterNotifier,
    required this.textAnimationController,
  });

  final ValueNotifier<int> counterNotifier;
  final AnimationController textAnimationController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counterNotifier,
      builder: (context, count, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AnimatedBuilder(
              animation: textAnimationController,
              builder: (context, _) {
                return Transform.scale(
                  scale: 1 + (0.12 * textAnimationController.value),
                  child: AutoSizeText(
                    count < 10 ? '0$count' : '$count',
                    wrapWords: false,
                    style: const TextStyle(
                      fontSize: 200,
                      fontFeatures: [FontFeature.tabularFigures()],
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
