import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A modern animated background widget for the app.
/// It uses a custom SVG with built-in CSS animations and parallax-ready layers.
class AnimatedBackground extends StatelessWidget {
  final Widget? child;

  const AnimatedBackground({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The minimal WhatsApp-style background
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/animated_bg.svg',
            fit: BoxFit.cover,
          ),
        ),
        
        // Almost invisible floating layer for very subtle depth
        const _SubtleFloatingLayer(),
        
        // Content on top
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

class _SubtleFloatingLayer extends StatefulWidget {
  const _SubtleFloatingLayer();

  @override
  State<_SubtleFloatingLayer> createState() => _SubtleFloatingLayerState();
}

class _SubtleFloatingLayerState extends State<_SubtleFloatingLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Very subtle icon 1
            Positioned(
              top: 300 + (10 * _controller.value),
              right: 100 + (5 * _controller.value),
              child: _buildSubtleIcon(Icons.chat_bubble_outline),
            ),
            // Very subtle icon 2
            Positioned(
              bottom: 400 + (10 * (1 - _controller.value)),
              left: 120 + (5 * _controller.value),
              child: _buildSubtleIcon(Icons.back_hand_outlined),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubtleIcon(IconData icon) {
    return Opacity(
      opacity: 0.05,
      child: Icon(
        icon,
        size: 40,
        color: const Color(0xFF4A5C53),
      ),
    );
  }
}
