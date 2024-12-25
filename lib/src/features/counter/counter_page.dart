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
  late final _meshController = AnimatedMeshGradientController();
  late final _animationController = AnimationController(
      duration: const Duration(milliseconds: 100), vsync: this);

  final _viewModel = GetIt.I<CounterPageViewModel>();

  @override
  void initState() {
    super.initState();
    _animationController.forward(from: 0);
    _meshController.start();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _animationController.dispose();
    _meshController.dispose();
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

  Widget _buildCounterBody() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: Colors.black45,
        onRefresh: _viewModel.reset,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
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

  void _onTap() {
    _viewModel.increment();
    _animationController.forward(from: 0);
  }

  Widget _buildCountText() {
    return ValueListenableBuilder(
      valueListenable: _viewModel.counterNotifier,
      builder: (context, count, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (0.12 * _animationController.value),
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

  Widget _buildBackground() {
    return ValueListenableBuilder(
      valueListenable: _viewModel.colorsNotifier,
      builder: (context, colors, __) {
        return SizedBox.expand(
          key: ValueKey(colors.toString()),
          child: AnimatedMeshGradient(
            controller: _meshController,
            colors: colors,
            options: AnimatedMeshGradientOptions(
              grain: 0.08,
              frequency: 7,
            ),
          ),
        );
      },
    );
  }
}
