import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'counter_page_view_model.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  final _viewModel = GetIt.I<CounterPageViewModel>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..forward(from: 0);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _animationController.dispose();
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
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
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
    // TODO: Use gradient for estetik
    return ValueListenableBuilder(
      valueListenable: _viewModel.colorNotifier,
      builder: (context, color, __) {
        return Container(
          color: color,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}
