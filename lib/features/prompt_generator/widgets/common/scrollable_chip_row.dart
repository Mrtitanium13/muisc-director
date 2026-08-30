import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:music_director/core/theme/app_colors.dart';
import 'package:music_director/core/utils/haptic_utils.dart';

/// Horizontal chip strip with small caret arrows when more chips are off-screen.
class ScrollableChipRow extends StatefulWidget {
  const ScrollableChipRow({
    super.key,
    required this.children,
    this.height = 44,
    this.spacing = 8,
  });

  final List<Widget> children;
  final double height;
  final double spacing;

  @override
  State<ScrollableChipRow> createState() => _ScrollableChipRowState();
}

class _ScrollableChipRowState extends State<ScrollableChipRow> {
  final _controller = ScrollController();
  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void didUpdateWidget(covariant ScrollableChipRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    _controller.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final max = pos.maxScrollExtent;
    final left = max > 2 && pos.pixels > 2;
    final right = max > 2 && pos.pixels < max - 2;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    } else if (max <= 2 && (_canLeft || _canRight)) {
      setState(() {
        _canLeft = false;
        _canRight = false;
      });
    }
  }

  void _nudge(bool forward) {
    if (!_controller.hasClients) return;
    hapticLight();
    final delta = forward ? 120.0 : -120.0;
    _controller.animateTo(
      (_controller.offset + delta).clamp(
        0.0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _updateArrows();
              return false;
            },
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: (_canLeft || _canRight) ? 22 : 0,
              ),
              itemCount: widget.children.length,
              separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
              itemBuilder: (context, i) =>
                  Center(child: widget.children[i]),
            ),
          ),
          if (_canLeft)
            Positioned(
              left: 0,
              child: _ArrowButton(
                icon: PhosphorIconsRegular.caretLeft,
                onTap: () => _nudge(false),
              ),
            ),
          if (_canRight)
            Positioned(
              right: 0,
              child: _ArrowButton(
                icon: PhosphorIconsRegular.caretRight,
                onTap: () => _nudge(true),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 14, color: AppColors.accentTertiary),
        ),
      ),
    );
  }
}
