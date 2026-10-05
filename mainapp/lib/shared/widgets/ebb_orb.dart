import 'package:flutter/material.dart';

class EbbOrb extends StatefulWidget {
  final double size;

  const EbbOrb({super.key, this.size = 120.0});

  @override
  State<EbbOrb> createState() => _EbbOrbState();
}

class _EbbOrbState extends State<EbbOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced motion accessibility setting
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    
    final orbWidget = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(76),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
    );

    if (disableAnimations) {
      return orbWidget;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: orbWidget,
    );
  }
}
